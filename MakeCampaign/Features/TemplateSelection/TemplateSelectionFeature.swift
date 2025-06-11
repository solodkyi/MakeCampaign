//
//  TemplateSelectionFeature.swift
//  MakeCampaign
//
//  Created by andriisolodkyi on 29.05.2025.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct TemplateSelectionFeature {
    @ObservableState
    struct State: Equatable {
        @Shared var campaign: Campaign
        var selectedTemplateID: Template.ID?
        var templates: IdentifiedArrayOf<Template> = Template.list
        
        var selectedTemplate: Template? {
            selectedTemplateID.flatMap { id in templates[id: id] }
        }
        
        init(campaign: Shared<Campaign>, templates: IdentifiedArrayOf<Template> = Template.list, selectedTemplateID: Template.ID? = nil) {
            self._campaign = campaign
            self.templates = templates
            self.selectedTemplateID = campaign.template?.id
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    enum Action: Equatable {
        case onAppear
        case templateSelected(Template)
        case delegate(Delegate)
        case doneButtonTapped
        case onImageRepositionFinished(CGFloat, CGSize, CGSize)
        
        @CasePathable
        @dynamicMemberLookup
        enum Delegate: Equatable {
            case templateApplied(Template, forCampaign: Campaign.ID)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
                
            case let .templateSelected(template):
                state.selectedTemplateID = template.id
                state.campaign.imageScale = 1
                state.campaign.imageOffset = .zero
                state.campaign.template = template
                
                return .none

            case .doneButtonTapped:
                if let templateID = state.selectedTemplateID,
                   let template = state.templates[id: templateID] {
                    return .run { [state] send in
                        await send(.delegate(.templateApplied(template, forCampaign: state.campaign.id)))
                        await self.dismiss()
                    }
                }
                return .none
            case let .onImageRepositionFinished(scale, offset, _):
                state.campaign.imageScale = scale
                state.campaign.imageOffset = offset
                
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

