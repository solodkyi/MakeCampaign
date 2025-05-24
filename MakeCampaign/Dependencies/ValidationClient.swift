import Foundation
import Dependencies

// MARK: - ValidationError

public enum ValidationError: Equatable {
    case empty
    case invalidFormat
    case invalidURL
    case missingImage
    case missingTemplate
    
    var message: String {
        switch self {
        case .empty:
            return "Поле не може бути пустим"
        case .invalidFormat:
            return "Неправильний формат"
        case .invalidURL:
            return "Неправильний формат URL"
        case .missingImage:
            return "Необхідно вибрати зображення"
        case .missingTemplate:
            return "Необхідно вибрати шаблон"
        }
    }
}

// MARK: - ValidationClient Interface

struct ValidationClient {
    var validateName: (String) -> [ValidationError]
    var validateTarget: (String) -> [ValidationError]
    var validateLink: (String) -> [ValidationError]
    var validateImage: (Data?) -> [ValidationError]
    var validateTemplate: (Template?) -> [ValidationError]
    var validateField: (CampaignDetailsFeature.State.Field?, CampaignDetailsFeature.State) -> [ValidationError]
}

// MARK: - DependencyKey

extension ValidationClient: DependencyKey {
    private static func validateNameImpl(_ name: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        if name.isEmpty {
            errors.append(.empty)
        }
        return errors
    }
    
    private static func validateTargetImpl(_ target: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        if !target.isEmpty {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            if formatter.number(from: target) == nil {
                errors.append(.invalidFormat)
            }
        }
        return errors
    }
    
    private static func validateLinkImpl(_ link: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        if !link.isEmpty {
            guard let url = URL(string: link) else {
                errors.append(.invalidURL)
                return errors
            }
            
            if url.scheme == nil {
                errors.append(.invalidURL)
                return errors
            }
            
            if url.host == nil || url.host?.isEmpty == true {
                errors.append(.invalidURL)
                return errors
            }
        }
        return errors
    }
    
    private static func validateImageImpl(_ imageData: Data?) -> [ValidationError] {
        var errors: [ValidationError] = []
        if imageData == nil {
            errors.append(.missingImage)
        }
        return errors
    }
    
    private static func validateTemplateImpl(_ template: Template?) -> [ValidationError] {
        var errors: [ValidationError] = []
        guard template != nil else {
            errors.append(.missingTemplate)
            return errors
        }
        return errors
    }
    
    static let liveValue = ValidationClient(
        validateName: validateNameImpl,
        validateTarget: validateTargetImpl,
        validateLink: validateLinkImpl,
        validateImage: validateImageImpl,
        validateTemplate: validateTemplateImpl,
        validateField: { field, state in
            guard let field = field else { return [] }
            
            switch field {
            case .name:
                return validateNameImpl(state.campaign.purpose)
            case .target:
                return validateTargetImpl(state.campaign.formattedTarget)
            case .link:
                return validateLinkImpl(state.campaign.jarURLString)
            case .image:
                return validateImageImpl(state.campaign.image?.raw)
            case .template:
                return validateTemplateImpl(state.campaign.template)
            }
        }
    )
    
    static let testValue = ValidationClient(
        validateName: { _ in [] },
        validateTarget: { _ in [] },
        validateLink: { _ in [] },
        validateImage: { _ in [] },
        validateTemplate: { _ in [] },
        validateField: { _, _ in [] }
    )
}

// MARK: - DependencyValues Extension

extension DependencyValues {
    var validationClient: ValidationClient {
        get { self[ValidationClient.self] }
        set { self[ValidationClient.self] = newValue }
    }
} 
