import ComposableArchitecture
import PhotosUI
import SwiftUI
import UIKit

struct CampaignCreationView: View {
    private enum EditorInput: Hashable {
        case campaignTitle
        case target
    }

    @Bindable var store: StoreOf<CampaignCreationFeature>
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @Environment(\.locale) private var locale
    @Dependency(\.campaignPosterPreviewAssetLoader) private var previewAssetLoader
    @Dependency(\.campaignPosterThumbnailClient) private var thumbnailClient
    @FocusState private var focusedInput: EditorInput?
    @State private var isTargetInputFocused = false
    @State private var pendingInputFocus: EditorInput?
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var previewAssetBuffer = CampaignPosterPreviewAssetBuffer()
    @State private var templateThumbnailBatch: CampaignPosterThumbnailBatch?
    @State private var selectedPosterElement: CampaignPosterElement?

    var body: some View {
        GeometryReader { proxy in
            let isTextEditing = focusedInput != nil || isTargetInputFocused
            let isPhotoPickerExpanded = store.isPhotoPickerExpanded
            let layout = CampaignEditorLayout.metrics(
                availableHeight: proxy.size.height,
                isTextEditing: isTextEditing
            )

            VStack(spacing: 0) {
                posterStage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.vertical, isTextEditing ? 6 : 10)
                    .frame(height: isPhotoPickerExpanded ? 0 : layout.posterStageHeight)
                    .background(editorBackground)
                    .clipped()
                    .opacity(isPhotoPickerExpanded ? 0 : 1)
                    .allowsHitTesting(!isPhotoPickerExpanded)

                editorTray(
                    showsTabs: !isTextEditing && !isPhotoPickerExpanded,
                    isPhotoPickerExpanded: isPhotoPickerExpanded
                )
                    .frame(
                        height: isTextEditing
                            ? nil
                            : (isPhotoPickerExpanded ? proxy.size.height : layout.trayHeight)
                    )
                    .frame(maxHeight: isTextEditing ? .infinity : nil)
            }
            .animation(.easeInOut(duration: 0.22), value: isTextEditing)
            .animation(.easeInOut(duration: 0.22), value: isPhotoPickerExpanded)
        }
        .ignoresSafeArea(
            .container,
            edges: store.selectedTab == .photo ? .bottom : []
        )
        .background(panelBackground.ignoresSafeArea())
        .navigationTitle("Редактор")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.exportOptionsButtonTapped)
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Експортувати постер")
                .accessibilityIdentifier("export-options-button")
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") {
                    dismissKeyboard()
                }
                .accessibilityIdentifier("keyboard-done-button")
            }
        }
        .sheet(item: $store.presentation, onDismiss: {
            store.send(.presentationDismissed)
        }) { presentation in
            switch presentation {
            case .export:
                exportSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            case let .share(payload):
                CampaignShareSheet(payload: payload)
                    .accessibilityIdentifier("campaign-system-share")
            }
        }
        .task(id: posterAssetInput) {
            await preparePreviewAssets(for: posterAssetInput)
        }
    }

    private var posterStage: some View {
        GeometryReader { proxy in
            let bounds = CGSize(
                width: min(350, max(0, proxy.size.width)),
                height: min(350, max(0, proxy.size.height))
            )
            let size = CampaignPosterLayout.previewSize(
                for: store.campaign.posterFormat,
                in: bounds
            )

            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        clearPosterInteraction()
                    }

                CampaignPosterView(
                    campaign: store.campaign,
                    assets: currentPreviewAssets,
                    allowsImageTransform: true,
                    selectedElement: selectedPosterElement,
                    onContentModeSelect: { contentMode in
                        store.send(.contentModeSelected(contentMode))
                    },
                    onImageTransformEnd: { scale, offset, referenceSize in
                        store.send(.imageTransformEnded(
                            scale: scale,
                            offset: offset,
                            referenceSize: referenceSize
                        ))
                    },
                    onElementTap: { element in
                        selectPosterElement(element, activatesInput: false)
                    },
                    onElementDoubleTap: { element in
                        selectPosterElement(element, activatesInput: true)
                    },
                    onBackgroundTap: {
                        clearPosterInteraction()
                    }
                )
                .frame(width: size.width, height: size.height)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.13), radius: 18, y: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func editorTray(
        showsTabs: Bool,
        isPhotoPickerExpanded: Bool
    ) -> some View {
        VStack(spacing: 0) {
            if showsTabs {
                tabBar
                Divider().opacity(colorScheme == .dark ? 0.3 : 0.7)
            }
            if store.selectedTab == .photo {
                photoPickerExpansionControl
                photoPanel
            } else {
                scrollableEditorPanel
            }
        }
        .background(panelBackground)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: isPhotoPickerExpanded ? 0 : 24,
                topTrailingRadius: isPhotoPickerExpanded ? 0 : 24
            )
        )
    }

    private var scrollableEditorPanel: some View {
        ScrollViewReader { proxy in
            ScrollView {
                editorPanel
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
            .onChange(of: focusedInput) { _, input in
                guard let input else { return }
                scrollEditor(to: input, using: proxy)
            }
            .onChange(of: isTargetInputFocused) { _, isFocused in
                guard isFocused else { return }
                scrollEditor(to: .target, using: proxy)
            }
            .onChange(of: store.campaign.purpose) { _, purpose in
                guard focusedInput == .campaignTitle else { return }
                if purpose.contains(where: \.isNewline) {
                    DispatchQueue.main.async {
                        store.campaign.purpose = purpose.filter { !$0.isNewline }
                        focusedInput = nil
                        DispatchQueue.main.async {
                            isTargetInputFocused = true
                        }
                    }
                    return
                }
                scrollEditor(to: .campaignTitle, using: proxy, animated: false)
            }
            .onChange(of: store.campaign.formattedTarget) { _, _ in
                guard isTargetInputFocused else { return }
                scrollEditor(to: .target, using: proxy, animated: false)
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(CampaignCreationFeature.State.Tab.allCases) { tab in
                Button {
                    clearPosterInteraction()
                    store.send(.tabSelected(tab))
                } label: {
                    VStack(spacing: 7) {
                        Image(systemName: tab.systemImage)
                        Text(tab.title)
                            .font(.caption.weight(.semibold))
                        Capsule()
                            .fill(store.selectedTab == tab ? accent : .clear)
                            .frame(height: 3)
                            .padding(.horizontal, 10)
                    }
                    .frame(maxWidth: .infinity, minHeight: 65)
                    .foregroundStyle(store.selectedTab == tab ? primaryText : secondaryText)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("editor-tab-\(tab.rawValue)")
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 2)
    }

    @ViewBuilder
    private var editorPanel: some View {
        switch store.selectedTab {
        case .photo: EmptyView()
        case .data: dataPanel
        case .template: templatePanel
        case .qr: qrPanel
        }
    }

    private var photoPanel: some View {
        PhotosPicker(
            "Обрати фото",
            selection: $photoItems,
            maxSelectionCount: 1,
            selectionBehavior: .continuous,
            matching: .images,
            preferredItemEncoding: .automatic
        )
        .photosPickerStyle(.inline)
        .photosPickerAccessoryVisibility(.hidden, edges: .bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("campaign-inline-photo-grid")
        .overlay(alignment: .top) {
            photoStatusOverlay
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("campaign-inline-photo-picker")
        .task(id: photoItems) {
            await loadSelectedPhoto()
        }
    }

    private var photoPickerExpansionControl: some View {
        ZStack {
            Capsule()
                .fill(secondaryText.opacity(0.32))
                .frame(width: 38, height: 5)

            HStack {
                Spacer()
                Image(systemName: store.isPhotoPickerExpanded
                    ? "chevron.down"
                    : "chevron.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(secondaryText)
                    .padding(.trailing, 18)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 34)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    if abs(value.translation.width) < 10,
                       abs(value.translation.height) < 10 {
                        store.send(.photoPickerExpansionButtonTapped)
                    } else {
                        store.send(
                            .photoPickerExpansionDragEnded(value.translation.height)
                        )
                    }
                }
        )
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(
            store.isPhotoPickerExpanded
                ? "Згорнути вибір фото"
                : "Розгорнути вибір фото"
        )
        .accessibilityIdentifier(
            store.isPhotoPickerExpanded
                ? "photo-picker-collapse-button"
                : "photo-picker-expand-button"
        )
    }

    @ViewBuilder
    private var photoStatusOverlay: some View {
        switch store.photoPhase {
        case .idle:
            EmptyView()

        case .processing:
            HStack(spacing: 8) {
                ProgressView()
                Text("Готуємо фото…")
            }
                .font(.caption.weight(.semibold))
                .foregroundStyle(primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())

        case let .failed(message):
            errorText(message)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
        }
    }

    private var dataPanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            labelledField("Назва збору", error: store.validation.title) {
                TextField("Наприклад, аптечки для підрозділу", text: $store.campaign.purpose, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(1...3)
                    .submitLabel(.next)
                    .focused($focusedInput, equals: .campaignTitle)
                    .onSubmit {
                        activateInput(.target)
                    }
                    .accessibilityIdentifier("campaign-title-field")
            }
            .id(EditorInput.campaignTitle)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("campaign-title-field-container")
            if let collected = store.campaign.jar?.details?.amountInHryvnias {
                labelledValue("Зібрано", value: collected.formattedAmount.appendingCurrency)
            }
            labelledField("Ціль збору", error: nil) {
                CampaignTargetField(
                    text: $store.campaign.formattedTarget,
                    isFocused: $isTargetInputFocused,
                    suffixColor: secondaryText,
                    onSubmit: dismissKeyboard
                )
            }
            .id(EditorInput.target)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("campaign-target-field-container")
        }
        .onAppear {
            activatePendingInputFocus()
        }
    }

    private var templatePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            fieldLabel("Родина обкладинки")
            templateThumbnailStrip

            fieldLabel("Формат")
            Picker("Формат постера", selection: $store.campaign.posterFormat) {
                Text("1:1").tag(Campaign.PosterFormat.square)
                Text("4:5").tag(Campaign.PosterFormat.portrait)
                Text("9:16").tag(Campaign.PosterFormat.story)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("poster-format-picker")
            if let error = store.validation.template { errorText(error) }
        }
    }

    @ViewBuilder
    private var templateThumbnailStrip: some View {
        let currentRequests = templateThumbnailRequests
        let refreshKeys = currentRequests.map(\.refreshKey)
        if let requests = templateThumbnailBatch?.retainedRequests(
            matching: currentRequests
        ) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10) {
                    ForEach(requests, id: \.template.id) { request in
                        let template = request.template
                        Button {
                            store.send(.templateSelected(template))
                        } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                CampaignPosterThumbnail(request: request)
                                    .frame(width: 84, height: 84)
                                Text(template.name)
                                    .font(.caption2.weight(.semibold))
                                    .lineLimit(1)
                                    .frame(width: 84, alignment: .leading)
                            }
                            .padding(6)
                            .background(
                                store.campaign.template?.id == template.id ? accent.opacity(0.14) : fieldBackground,
                                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                            )
                            .overlay {
                                if store.campaign.template?.id == template.id {
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .stroke(accent, lineWidth: 2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("template-\(template.id)")
                        .accessibilityValue(
                            store.campaign.template?.id == template.id
                                ? "Вибрано"
                                : ""
                        )
                    }
                }
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("campaign-template-thumbnail-strip")
        } else {
            HStack(spacing: 8) {
                ProgressView()
                Text("Готуємо шаблони…")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }
            .frame(height: 119)
            .frame(maxWidth: .infinity, alignment: .leading)
            .task(id: refreshKeys) {
                templateThumbnailBatch = nil
                await thumbnailClient.prewarm(currentRequests)
                guard !Task.isCancelled else { return }
                templateThumbnailBatch = CampaignPosterThumbnailBatch(
                    requests: currentRequests
                )
            }
        }
    }

    private var templateThumbnailRequests: [CampaignPosterThumbnailRequest] {
        Template.list.map { template in
            CampaignPosterThumbnailRequest(
                campaign: store.campaign,
                template: template,
                composition: .poster,
                assets: currentPreviewAssets,
                pointSize: CGSize(width: 84, height: 84),
                displayScale: displayScale,
                colorScheme: colorScheme,
                locale: locale
            )
        }
    }

    private var qrPanel: some View {
        VStack(alignment: .leading, spacing: 13) {
            labelledField("Посилання на банку", error: store.validation.qrLink) {
                TextField("https://send.monobank.ua/jar/…", text: $store.campaign.jarURLString)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("campaign-jar-link-field")
            }
            Toggle(isOn: $store.campaign.showsQRCode) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Показувати QR").font(.subheadline.weight(.semibold))
                    Text("На постері та в експорті")
                        .font(.caption2)
                        .foregroundStyle(secondaryText)
                }
            }
            .tint(accent)
            .accessibilityIdentifier("campaign-qr-toggle")
            labelledField("Підпис", error: nil) {
                TextField("Підтримайте збір", text: $store.campaign.shareCaption, axis: .vertical)
                    .lineLimit(2...4)
                    .accessibilityIdentifier("campaign-caption-field")
            }
        }
    }

    private var exportSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Експортувати обкладинку")
                    .font(.title2.bold())

                HStack(spacing: 9) {
                    exportFormatOption(.square, title: "1080×1080", subtitle: "Допис")
                    exportFormatOption(.portrait, title: "1080×1350", subtitle: "Портрет")
                    exportFormatOption(.story, title: "1080×1920", subtitle: "Історія")
                }

                Text("Обкладинка збереже якість фото, ціль і QR-код банки.")
                    .font(.footnote)
                    .foregroundStyle(secondaryText)

                validationSummary

                Button {
                    store.send(.exportButtonTapped)
                } label: {
                    HStack(spacing: 10) {
                        if store.isRendering { ProgressView().tint(.white) }
                        Image(systemName: "square.and.arrow.up")
                        Text(store.isRendering ? "Створюємо постер…" : "Зберегти й поширити")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(accent, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                }
                .disabled(store.isRendering)
                .accessibilityIdentifier("save-and-share-button")
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("campaign-export-sheet")
    }

    @ViewBuilder
    private var validationSummary: some View {
        let messages = [
            store.validation.title,
            store.validation.photo,
            store.validation.template,
            store.validation.qrLink,
        ].compactMap { $0 }
        if !messages.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Text("Щоб створити постер:").font(.subheadline.bold())
                ForEach(messages, id: \.self) { message in
                    Text("• \(message)").font(.subheadline)
                }
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("campaign-validation-summary")
        } else if let error = store.renderError {
            errorText(error).accessibilityIdentifier("campaign-render-error")
        }
    }

    private func exportFormatOption(
        _ format: Campaign.PosterFormat,
        title: String,
        subtitle: String
    ) -> some View {
        Button {
            store.send(.binding(.set(\.campaign.posterFormat, format)))
        } label: {
            VStack(spacing: 6) {
                Text(title).font(.caption2.monospaced().weight(.bold))
                Text(subtitle).font(.caption2)
            }
            .foregroundStyle(store.campaign.posterFormat == format ? primaryText : secondaryText)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(
                store.campaign.posterFormat == format ? accent.opacity(0.13) : fieldBackground,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(store.campaign.posterFormat == format ? accent : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("export-format-\(format.rawValue)")
    }

    private func loadSelectedPhoto() async {
        guard let item = photoItems.last else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                store.send(.photoProcessingFailed)
                return
            }
            try Task.checkCancellation()
            store.send(.photoPicked(data))
        } catch is CancellationError {
            return
        } catch {
            store.send(.photoProcessingFailed)
        }
    }

    private func selectPosterElement(
        _ element: CampaignPosterElement,
        activatesInput: Bool
    ) {
        selectedPosterElement = element
        pendingInputFocus = nil

        switch element {
        case .photo:
            focusedInput = nil
            isTargetInputFocused = false
            store.send(.tabSelected(.photo))

        case .campaignTitle, .target:
            let input: EditorInput = element == .campaignTitle ? .campaignTitle : .target
            if activatesInput {
                pendingInputFocus = input
            } else {
                focusedInput = nil
                isTargetInputFocused = false
            }

            let dataPanelIsVisible = store.selectedTab == .data
            store.send(.tabSelected(.data))
            if activatesInput && dataPanelIsVisible {
                activateInput(input)
                pendingInputFocus = nil
            }

        case .qr:
            focusedInput = nil
            isTargetInputFocused = false
            store.send(.tabSelected(.qr))
        }
    }

    private func activatePendingInputFocus() {
        guard let pendingInputFocus else { return }
        activateInput(pendingInputFocus)
        self.pendingInputFocus = nil
    }

    private func activateInput(_ input: EditorInput) {
        switch input {
        case .campaignTitle:
            isTargetInputFocused = false
            focusedInput = .campaignTitle
        case .target:
            focusedInput = nil
            isTargetInputFocused = true
        }
    }

    private func clearPosterInteraction() {
        selectedPosterElement = nil
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        pendingInputFocus = nil
        focusedInput = nil
        isTargetInputFocused = false
    }

    private func scrollEditor(
        to input: EditorInput,
        using proxy: ScrollViewProxy,
        animated: Bool = true
    ) {
        let scroll = {
            proxy.scrollTo(input, anchor: input == .target ? .bottom : .top)
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.2), scroll)
        } else {
            scroll()
        }
    }

    private var posterAssetInput: CampaignPosterPreviewAssetInput {
        CampaignPosterPreviewAssetInput(campaign: store.campaign)
    }

    private var currentPreviewAssets: CampaignPosterPreviewAssets {
        previewAssetBuffer.assets
    }

    private func preparePreviewAssets(
        for input: CampaignPosterPreviewAssetInput
    ) async {
        previewAssetBuffer.beginLoading(input)
        do {
            let assets = try await previewAssetLoader.load(input)
            try Task.checkCancellation()
            previewAssetBuffer.commit(assets, for: input)
        } catch {
            guard !Task.isCancelled else { return }
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.monospaced().weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(secondaryText)
    }

    private func labelledValue(_ title: String, value: String) -> some View {
        labelledField(title, error: nil) {
            Text(value).font(.body.monospacedDigit())
        }
    }

    private func labelledField<Content: View>(
        _ title: String,
        error: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            fieldLabel(title)
            content()
                .padding(.horizontal, 13)
                .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                .background(fieldBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            if let error { errorText(error) }
        }
    }

    private func errorText(_ message: String) -> some View {
        Text(message).font(.caption).foregroundStyle(.red)
    }

    private var editorBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.05, green: 0.05, blue: 0.045)
            : Color(red: 0.95, green: 0.94, blue: 0.925)
    }

    private var panelBackground: Color {
        colorScheme == .dark ? Color(red: 0.10, green: 0.10, blue: 0.09) : .white
    }

    private var fieldBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.045)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.58) : .black.opacity(0.53)
    }

    private var accent: Color {
        Color(red: 0.88, green: 0.34, blue: 0.16)
    }
}

enum CampaignEditorLayout {
    struct Metrics: Equatable {
        let trayHeight: CGFloat
        let posterStageHeight: CGFloat
    }

    static func metrics(
        availableHeight: CGFloat,
        isTextEditing: Bool
    ) -> Metrics {
        let availableHeight = availableHeight.isFinite
            ? max(0, availableHeight)
            : 0
        let desiredTrayHeight = min(
            364,
            max(330, availableHeight * 0.47)
        )
        let trayHeight = min(availableHeight, desiredTrayHeight)
        let desiredEditingPosterHeight = min(
            220,
            max(190, availableHeight * 0.5)
        ) + 12
        let posterStageHeight = isTextEditing
            ? min(availableHeight, desiredEditingPosterHeight)
            : max(0, availableHeight - trayHeight)
        return Metrics(
            trayHeight: trayHeight,
            posterStageHeight: posterStageHeight
        )
    }
}

enum CampaignTargetInputFormatter {
    static func format(_ input: String) -> String {
        guard !input.isEmpty else { return "" }
        if input.last == "," {
            return format(String(input.dropLast())) + ","
        }

        let normalizedInput = normalizingLocalizedDecimalSeparator(in: input)
        let ungrouped = normalizedInput.replacingOccurrences(of: ",", with: "")
        let parts = ungrouped.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard
            parts.count <= 2,
            let integerPart = parts.first,
            !integerPart.isEmpty,
            integerPart.allSatisfy({ $0.isASCII && $0.isNumber }),
            parts.dropFirst().allSatisfy({ part in
                part.allSatisfy { $0.isASCII && $0.isNumber }
            }),
            let integer = Decimal(
                string: String(integerPart),
                locale: Locale(identifier: "en_US_POSIX")
            )
        else {
            return input
        }

        let formatter = NumberFormatter.defaultCurrencyFormatter
        formatter.maximumFractionDigits = 0
        guard let groupedInteger = formatter.string(from: integer as NSDecimalNumber) else {
            return input
        }

        guard parts.count == 2 else { return groupedInteger }
        return groupedInteger + "." + parts[1]
    }

    private static func normalizingLocalizedDecimalSeparator(in input: String) -> String {
        guard
            !input.contains("."),
            let lastComma = input.lastIndex(of: ",")
        else {
            return input
        }

        let fraction = input[input.index(after: lastComma)...]
        guard
            fraction.count < 3,
            fraction.allSatisfy({ $0.isASCII && $0.isNumber })
        else {
            return input
        }

        var normalized = input
        normalized.replaceSubrange(lastComma...lastComma, with: ".")
        return normalized
    }
}

private struct CampaignTargetField: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    @State private var input: String

    let suffixColor: Color
    let onSubmit: () -> Void

    init(
        text: Binding<String>,
        isFocused: Binding<Bool>,
        suffixColor: Color,
        onSubmit: @escaping () -> Void
    ) {
        self._text = text
        self._isFocused = isFocused
        self._input = State(initialValue: text.wrappedValue)
        self.suffixColor = suffixColor
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: 6) {
            CampaignTargetTextField(
                text: $input,
                isFocused: $isFocused,
                onSubmit: onSubmit
            )
                .onChange(of: input) { _, newValue in
                    if text != newValue {
                        text = newValue
                    }
                }

            if !input.isEmpty {
                Text("грн.")
                    .foregroundStyle(suffixColor)
            }
        }
    }
}

private struct CampaignTargetTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> CampaignTargetUITextField {
        let textField = CampaignTargetUITextField()
        textField.delegate = context.coordinator
        textField.didMoveToWindowHandler = { [weak textField, weak coordinator = context.coordinator] in
            guard let textField,
                  let coordinator,
                  textField.window != nil,
                  coordinator.parent.isFocused,
                  !textField.isFirstResponder else { return }
            textField.becomeFirstResponder()
        }
        textField.keyboardType = .decimalPad
        textField.returnKeyType = .done
        let inputToolbar = UIToolbar()
        inputToolbar.sizeToFit()
        let doneButton = UIBarButtonItem(
            title: "Готово",
            style: .done,
            target: context.coordinator,
            action: #selector(Coordinator.submit)
        )
        doneButton.accessibilityIdentifier = "keyboard-done-button"
        inputToolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            doneButton,
        ]
        textField.inputAccessoryView = inputToolbar
        textField.borderStyle = .none
        textField.adjustsFontForContentSizeCategory = true
        textField.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
            weight: .regular
        )
        textField.textColor = .label
        textField.tintColor = .tintColor
        textField.attributedPlaceholder = NSAttributedString(
            string: "Необов’язково",
            attributes: [.foregroundColor: UIColor.placeholderText]
        )
        textField.accessibilityIdentifier = "campaign-target-field"
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.text = text
        return textField
    }

    func updateUIView(_ textField: CampaignTargetUITextField, context: Context) {
        context.coordinator.parent = self
        if textField.text != text {
            textField.text = text
        }
        if isFocused && textField.window != nil && !textField.isFirstResponder {
            DispatchQueue.main.async { [weak textField, weak coordinator = context.coordinator] in
                guard let textField,
                      let coordinator,
                      coordinator.parent.isFocused,
                      textField.window != nil,
                      !textField.isFirstResponder else { return }
                textField.becomeFirstResponder()
            }
        } else if !isFocused && textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CampaignTargetTextField

        init(parent: CampaignTargetTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if !parent.isFocused {
                parent.isFocused = true
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.isFocused {
                parent.isFocused = false
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            return false
        }

        @objc func submit() {
            parent.onSubmit()
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let currentText = textField.text ?? ""
            guard let swiftRange = Range(range, in: currentText) else {
                return false
            }

            let candidate = currentText.replacingCharacters(in: swiftRange, with: string)
            let formatted = CampaignTargetInputFormatter.format(candidate)
            let candidateCursorOffset = range.location + (string as NSString).length
            let safeCursorOffset = min(candidateCursorOffset, (candidate as NSString).length)
            let candidatePrefix = (candidate as NSString).substring(to: safeCursorOffset)
            let formattedPrefix = CampaignTargetInputFormatter.format(candidatePrefix)
            let formattedCursorOffset = min(
                (formattedPrefix as NSString).length,
                (formatted as NSString).length
            )

            textField.text = formatted
            parent.text = formatted

            if let cursorPosition = textField.position(
                from: textField.beginningOfDocument,
                offset: formattedCursorOffset
            ) {
                textField.selectedTextRange = textField.textRange(
                    from: cursorPosition,
                    to: cursorPosition
                )
            }

            return false
        }
    }
}

private final class CampaignTargetUITextField: UITextField {
    var didMoveToWindowHandler: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        didMoveToWindowHandler?()
    }
}
