//
//  JBDatePicker.swift
//  CalendarDatePickerViewController
//
//  Created by Josh Birnholz on 10/29/19.
//  Copyright © 2019 Josh Birnholz. All rights reserved.
//

#if canImport(UIKit)
import UIKit


public protocol JBDatePicker: UIResponder {
	var date: Date { get set }
	var calendar: Calendar! { get set }
	var locale: Locale? { get set }
	var minimumDate: Date? { get set }
	var maximumDate: Date? { get set }
	var datePickerMode: UIDatePicker.Mode { get set }
}
#endif
