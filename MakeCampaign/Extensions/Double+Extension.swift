//
//  Double+Extension.swift
//  MakeCampaign
//
//  Created by Andrii Solodkyi on 5/2/25.
//

import Foundation

public extension NumberFormatter {
    static var defaultCurrencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = "."
        return formatter
    }
}

public extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter.defaultCurrencyFormatter
        
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

public extension String {
    var asCurrencyDouble: Double? {
        let formatter = NumberFormatter.defaultCurrencyFormatter
        
        guard let number = formatter.number(from: self)?.doubleValue else {
            return nil
        }
        
        return number
    }
}
