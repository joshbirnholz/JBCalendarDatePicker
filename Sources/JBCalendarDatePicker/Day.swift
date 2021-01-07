//
//  Day.swift
//  CalendarDatePickerViewController
//
//  Created by Josh Birnholz on 28/10/2019.
//  Copyright © 2019 Josh Birnholz. All rights reserved.
//

import Foundation

struct Day: Equatable, Hashable {
	var calendar: Calendar
	var day: Int
	var month: Int
	var year: Int
	
	var date: Date {
		DateComponents(calendar: calendar, year: year, month: month, day: day).date!
	}
	
	var isToday: Bool {
		let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
		var components = DateComponents(calendar: calendar, year: year, month: month, day: day)
		let date = calendar.date(from: components)!
		components = calendar.dateComponents([.year, .month, .day], from: date)
		return todayComponents.day == components.day && todayComponents.month == components.month && todayComponents.year == components.year
	}
	
	static func == (lhs: Day, rhs: Day) -> Bool {
		if lhs.day == rhs.day && lhs.month == rhs.month && lhs.year == rhs.year {
			return true
		}
		return lhs.date == rhs.date
	}
}
