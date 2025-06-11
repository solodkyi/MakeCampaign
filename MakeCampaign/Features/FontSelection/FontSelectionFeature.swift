//
//  FontSelectionFeature.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 6/9/25.
//

import ComposableArchitecture
import Sharing

@Reducer
struct FontSelectionFeature {
    @ObservableState
    struct State {
        var selectedFont: Font
        var fonts: IdentifiedArrayOf<Font> = []
    }
    
    enum Action {
        
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none
        }
    }
}
