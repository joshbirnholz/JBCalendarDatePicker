//
//  JBDatePickerViewController.swift
//  CalendarDatePickerViewController
//
//  Created by Josh Birnholz on 28/10/2019.
//  Copyright © 2019 Josh Birnholz. All rights reserved.
//

import UIKit

public class JBDatePickerViewController: UIViewController, DateInputViewDelegate, JBDatePicker {
	
	// MARK: Public interface
	
	private var keyboardType: UIKeyboardType {
		return .numberPad
	}
	
	/// Use this property to change the type of information displayed by the date picker. It determines whether the date picker allows selection of a date, a time, or both date and time. The default mode is `UIDatePicker.Mode.dateAndTime`. See `UIDatePicker.Mode` for a list of mode constants.
	///
	/// Setting this property to `UIDatePicker.Mode.countDownTimer` has no effect; this date picker does not support the countdown timer mode.
	public var datePickerMode: UIDatePicker.Mode = .dateAndTime {
		didSet {
			if datePickerMode == .countDownTimer {
				datePickerMode = oldValue
			}
		}
	}
	
	private var dateInputView: DateInputView! {
		return (view as! DateInputView)
	}
	
	public var calendar: Calendar! = Calendar.current {
		didSet {
			if calendar == nil {
				calendar = .current
			}
		}
	}
	
	public var locale: Locale? = .current {
		didSet {
			calendar.locale = locale
		}
	}
	
	public var date: Date = Date() {
		didSet {
			switch (minimumDate, maximumDate) {
			case(let minimumDate?, let maximumDate?) where minimumDate < maximumDate :
				date = min(max(date, minimumDate), maximumDate)
			case (let minimumDate?, nil):
				date = max(date, minimumDate)
			case (nil, let maximumDate?):
				date = min(date, maximumDate)
			default:
				break
			}
			updateLabelText()
			setTextInputString("", updatingLabel: false)
			print("date set to \(date)")
			isPM = (12...23).contains(calendar.component(.hour, from: date))
			
			presentedCalendar?.delegate = nil
			presentedCalendar?.date = date
			presentedCalendar?.delegate = self
		}
	}
	
	public var minimumDate: Date? {
		didSet {
			updateLabelText()
		}
	}
	public var maximumDate: Date? {
		didSet {
			updateLabelText()
		}
	}
	
	private var usableMinimumDate: Date? {
		if let minimumDate = minimumDate {
			if let maximumDate = maximumDate {
				if minimumDate < maximumDate {
					return minimumDate
				} else {
					return nil
				}
			}
			return minimumDate
		}
		
		return nil
	}
	
	private var usableMaximumDate: Date? {
		if let maximumDate = maximumDate {
			if let minimumDate = minimumDate {
				if minimumDate < maximumDate {
					return maximumDate
				} else {
					return nil
				}
			}
			return maximumDate
		}
		
		return nil
	}
	
	fileprivate var _textInputString: String = ""
	fileprivate var textInputString: String { return _textInputString }
	
	fileprivate func setTextInputString(_ newValue: String, updatingLabel: Bool) {
		_textInputString = newValue
		if updatingLabel, let selectedDatePart = selectedDatePart {
			label(for: selectedDatePart).text = _textInputString
		}
	}
	
	// MARK: Init
	
	public required init?(coder: NSCoder) {
		super.init(nibName: "JBDatePickerViewController", bundle: Bundle(for: Self.self))
		commonInit()
	}
	
	public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		commonInit()
	}
	
	public init() {
		super.init(nibName: "JBDatePickerViewController", bundle: Bundle(for: Self.self))
		commonInit()
	}
	
	private func commonInit() {
		
	}
	
	@IBOutlet private var labels: [UILabel]!
	@IBOutlet private var slashLabels: [UILabel]!
	@IBOutlet private weak var fullStackView: UIStackView!
	@IBOutlet private weak var datePartsStackView: UIStackView!
	@IBOutlet private weak var timePartsStackView: UIStackView!
	
	override public func viewDidLoad() {
        super.viewDidLoad()
		calendar.locale = locale ?? .current
		
		view.backgroundColor = .clear
		dateInputView.delegate = self
		
		#if targetEnvironment(macCatalyst)
		view.tintColor = .systemAccent
		#endif
		
		datePartsStackView.isHidden = datePickerMode == .time
		timePartsStackView.isHidden = datePickerMode == .date
		
		setupTextFields()
		
		updateLabelText()
		
	}
	
	override public var canBecomeFirstResponder: Bool {
		return dateInputView.canBecomeFirstResponder
	}
	
	override public func becomeFirstResponder() -> Bool {
		print(type(of: self), #function)
		if selectedDatePart == nil {
			selectedDatePart = dateParts.first
		}
		return dateInputView.becomeFirstResponder()
	}
	
	override public func resignFirstResponder() -> Bool {
		print(type(of: self), #function)
		selectedDatePart = nil
		
//		if let presented = presentedCalendar {
//			dismiss(animated: true, completion: nil)
//		}
		
		return super.resignFirstResponder()
	}
	
	@objc private func tapGestureRecognized(_ sender: UITapGestureRecognizer) {
		guard let label = sender.view as? UILabel, let datePart = self.datePart(for: label) else { return }
		selectedDatePart = datePart
		_ = dateInputView.becomeFirstResponder()
	}
	
	private var isPM = false
	
	private enum DatePart: String, CaseIterable {
		case day = "dd"
		case month = "MM"
		case year = "yyyy"
		case hour12 = "h"
		case hour24 = "HH"
		case minute = "mm"
		case amPM = "a"
		
		func set(value: Int, of components: inout DateComponents, using calendar: Calendar, isPM: Bool) {
			switch self {
			case .day:
				components.setValue(value, for: .day)
			case .month:
				#warning("TODO: Set day to last day of month when the date range for the new month doesn't include the old day.")
				components.setValue(value, for: .month)
			case .year:
				components.setValue(value, for: .year)
			case .hour12:
				var value = value
				
				if value == 12 && !isPM {
					value = 0
				} else if (1...11).contains(value) && isPM {
					value += 12
				}
				
				components.setValue(value, for: .hour)
			case .hour24:
				components.setValue(value, for: .hour)
			case .minute:
				components.setValue(value, for: .minute)
			case .amPM:
				break
			}
		}
		
		func maxComponentLength(using calendar: Calendar) -> Int {
			if self == .amPM {
				return max(calendar.amSymbol.count, calendar.pmSymbol.count)
			} else if self == .hour12 {
				return 2
			}
			
			return rawValue.count
		}
	}
	
	private var presentedCalendar: JBCalendarViewController? {
		return presentedViewController as? JBCalendarViewController
	}
	
	private var selectedDatePart: DatePart? {
		didSet {
			for datePart in visibleDateParts {
				let label = self.label(for: datePart)
				let isSelected = selectedDatePart == datePart
				label.backgroundColor = isSelected ? view.tintColor : nil
				label.textColor = isSelected ? .lightLabel : .label
			}
			
			self.setTextInputString("", updatingLabel: false)
			
			guard let selectedDatePart = selectedDatePart else {
//				presentedCalendar?.dismiss(animated: true, completion: nil)
				return
			}
			
			if selectedDatePart == .day || selectedDatePart == .month || selectedDatePart == .year && presentedCalendar == nil {
				let calendarVC = JBCalendarViewController()
				calendarVC.date = date
				calendarVC.calendar = calendar
				calendarVC.locale = locale
				calendarVC.minimumDate = minimumDate
				calendarVC.maximumDate = maximumDate
				calendarVC.popoverPresentationController?.sourceView = datePartsStackView
				calendarVC.popoverPresentationController?.sourceRect = datePartsStackView.frame
//				calendarVC.popoverPresentationController?.sourceRect = dayLabel.frame
				calendarVC.popoverPresentationController?.permittedArrowDirections = [.up]
				calendarVC.popoverPresentationController?.passthroughViews = [fullStackView]
				calendarVC.delegate = self
				self.present(calendarVC, animated: true, completion: nil)
			} else {
//				presentedCalendar?.dismiss(animated: true, completion: nil)
			}
		}
	}
	
	private var dateParts: [DatePart]! {
		didSet {
			amPMLabel.isHidden = !dateParts.contains(.hour12)
		}
	}
	
	private var yearLabel: UILabel {
		let index = dateParts.firstIndex(of: .year)!
		return labels[index]
	}
	
	private var monthLabel: UILabel {
		let index = dateParts.firstIndex(of: .month)!
		return labels[index]
	}
	
	private var dayLabel: UILabel {
		let index = dateParts.firstIndex(of: .day)!
		return labels[index]
	}
	
	@IBOutlet private weak var hourLabel: UILabel!
	@IBOutlet private weak var minuteLabel: UILabel!
	@IBOutlet private weak var amPMLabel: UILabel!
	
	private func setupTextFields() {
		var allLabels = labels ?? []
		allLabels.append(hourLabel)
		allLabels.append(minuteLabel)
		allLabels.append(amPMLabel)
		for label in allLabels {
			label.font = UIFont.monospacedDigitSystemFont(ofSize: label.font!.pointSize, weight: .regular)
			label.sizeToFit()
			NSLayoutConstraint(item: label, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: label.frame.size.width).isActive = true
			
			label.layer.masksToBounds = true
			label.layer.cornerRadius = 4
			label.backgroundColor = .clear
			label.textColor = .label
			
			let gesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(_:)))
			label.addGestureRecognizer(gesture)
			label.isUserInteractionEnabled = true
		}
		
		let template = dateTemplate
		let dateFormat = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: locale ?? .current)!
		let components = dateFormat.split(maxSplits: .max, omittingEmptySubsequences: true, whereSeparator: { character -> Bool in
			!template.contains(character.lowercased())
		})
		dateParts = components.compactMap { DatePart(rawValue: String($0)) }
	}
	
	private let dateTemplate: String = "MMddyyyyhmma"
	
	private let formatter = DateFormatter()
	
	private var visibleDateParts: [DatePart] {
		switch datePickerMode {
		case .time:
			if dateParts.contains(.hour12) {
				return [.hour12, .minute, .amPM]
			} else {
				return [.hour24, .minute]
			}
		case .date:
			return [.year, .month, .day]
		default:
			var returnValue: [DatePart] = [.year, .month, .day]
			if dateParts.contains(.hour12) {
				returnValue.append(contentsOf: [.hour12, .minute, .amPM])
			} else {
				returnValue.append(contentsOf: [.hour24, .minute])
			}
			return returnValue
		}
	}
	
//	private var labelsAndDateParts: [(UILabel, DatePart)] {
//		return visibleDateParts.map { (self.label(for: $0), $0) }
//	}
	
	private func label(for datePart: DatePart) -> UILabel {
		switch datePart {
		case .day: return dayLabel
		case .month: return monthLabel
		case .year: return yearLabel
		case .hour12: return hourLabel
		case .hour24: return hourLabel
		case .minute: return minuteLabel
		case .amPM: return amPMLabel
		}
	}
	
	private func datePart(for label: UILabel) -> DatePart? {
		switch label {
		case yearLabel: return .year
		case monthLabel: return .month
		case dayLabel: return .day
		case hourLabel:
			if dateParts.contains(.hour12) {
				return .hour12
			}
			return .hour24
		case minuteLabel: return .minute
		case amPMLabel: return .amPM
		default: return nil
		}
	}
	
	private func updateLabelText() {
		for datePart in visibleDateParts {
			formatter.dateFormat = datePart.rawValue
			label(for: datePart).text = String(formatter.string(from: date).prefix(datePart.maxComponentLength(using: calendar)))
		}
		
		formatter.dateFormat = "a"
		amPMLabel.text = formatter.string(from: date)
	}
	
	private var finalizeEditTimer: Timer? {
		didSet {
			oldValue?.invalidate()
		}
	}

}

extension JBDatePickerViewController: UIKeyInput {
	public var hasText: Bool {
		return !textInputString.isEmpty
	}
	
	fileprivate func selectNextDatePart() {
		#warning("TODO: skip over hidden date parts")
		guard let selectedDatePart = selectedDatePart else { return }
		if let index = dateParts.lastIndex(of: selectedDatePart), dateParts.indices.contains(index+1) {
			self.selectedDatePart = dateParts[index+1]
		} else {
			self.selectedDatePart = dateParts.first
		}
	}
	
	public func insertText(_ text: String) {
		guard let selectedDatePart = selectedDatePart else { return }
		
		if text == "\t" {
			finalize(datePart: selectedDatePart)
			
			selectNextDatePart()
			
			return
		}
		
		if selectedDatePart == .amPM {
			setTextInputString(text, updatingLabel: true)
			finalize(datePart: selectedDatePart)
			return
		}
		
		guard let proposedValue = Int(textInputString + text) else { return }
		
		let validValues: [Int] = {
			switch selectedDatePart {
			case .day:
				return calendar.range(of: .day, in: .month, for: date).map(Array.init) ?? []
			case .month:
				return calendar.range(of: .month, in: .year, for: date).map(Array.init) ?? []
			case .year:
				return Array(1...9999)
			case .hour12:
				return Array(1...12)
			case .hour24:
				return Array(0...23)
			case .minute:
				return Array(0...59)
			case .amPM:
				return []
			}
		}()
		
		let valueIsValid: Bool = {
			return validValues.contains(proposedValue)
		}()
		
		guard valueIsValid else { return }
		
		setTextInputString(String(proposedValue), updatingLabel: true)
		
		if textInputString.count >= selectedDatePart.maxComponentLength(using: calendar) {
			finalize(datePart: selectedDatePart)
		} else {
			startFinalizeTimer(datePart: selectedDatePart)
		}
		
	}
	
	public func deleteBackward() {
		
		guard !textInputString.isEmpty else { return }
		var input = textInputString
		input.removeLast()
		setTextInputString(input, updatingLabel: true)
		
		if let selectedDatePart = selectedDatePart, !textInputString.isEmpty {
			startFinalizeTimer(datePart: selectedDatePart)
		}
	}
	
	private func startFinalizeTimer(datePart: DatePart) {
		finalizeEditTimer = Timer(timeInterval: 1, repeats: false) { timer in
			self.finalize(datePart: datePart)
		}
		RunLoop.main.add(finalizeEditTimer!, forMode: .common)
	}
	
	private func finalize(datePart: DatePart) {
		var components = calendar.dateComponents([.timeZone, .year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
		if let value = Int(textInputString) {
			datePart.set(value: value, of: &components, using: calendar, isPM: isPM)
			if let date = calendar.date(from: components) {
				self.date = date
			} else {
				updateLabelText()
			}
		} else if datePart == .amPM && !textInputString.isEmpty {
			if calendar.amSymbol.lowercased().hasPrefix(textInputString.lowercased()) && isPM {
				isPM = false
				print("setting to am")
				components.hour! -= 12
			} else if calendar.pmSymbol.lowercased().hasPrefix(textInputString.lowercased()) && !isPM {
				isPM = true
				print("setting to pm")
				components.hour! += 12
			}
			if let date = calendar.date(from: components) {
				self.date = date
			} else {
				updateLabelText()
			}
		}
		setTextInputString("", updatingLabel: false)
		finalizeEditTimer?.invalidate()
	}

}

extension JBDatePickerViewController: JBCalendarViewControllerDelegate {
	func calendarViewControllerDateChanged(_ calendarViewController: JBCalendarViewController) {
		self.date = calendarViewController.date
	}
	
	func calendarViewControllerWillDismiss(_ calendarViewController: JBCalendarViewController) {
		_ = dateInputView.resignFirstResponder()
	}
	
	func calendarViewControllerDidDismiss(_ calendarViewController: JBCalendarViewController) {
		
	}
}
