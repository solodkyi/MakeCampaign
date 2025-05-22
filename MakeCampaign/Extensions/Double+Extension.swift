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
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter
    }
}

public extension Double {
    var formattedAmount: String {
        let formatter = NumberFormatter.defaultCurrencyFormatter
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            formatter.maximumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 2
        }
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
