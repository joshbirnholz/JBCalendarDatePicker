//
//  CalendarDatePickerViewController.swift
//  Calendar Picker
//
//  Created by Josh Birnholz on 10/27/19.
//  Copyright © 2019 Josh Birnholz. All rights reserved.
//

import UIKit

public protocol JBCalendarViewControllerDelegate: class {
	func calendarViewControllerDateChanged(_ calendarViewController: JBCalendarViewController)
	func calendarViewControllerWillDismiss(_ calendarViewController: JBCalendarViewController)
	func calendarViewControllerDidDismiss(_ calendarViewController: JBCalendarViewController)
}

public class JBCalendarViewController: UIViewController, JBDatePicker {
	
	weak var delegate: JBCalendarViewControllerDelegate?

	@IBOutlet private weak var monthLabel: UILabel!
	@IBOutlet private weak var collectionView: UICollectionView!
	
	@IBOutlet private var weekSymbolLabels: [UILabel]!
	
	/// This property always returns `UIDatePicker.Mode.date`. Setting this property to a new value does nothing. It is not possible to change the date picker mode of the calendar interface.
	public var datePickerMode: UIDatePicker.Mode {
		get {
			return .date
		}
		set {
			
		}
	}
	
	public var calendar: Calendar! = Calendar.current {
		didSet {
			if calendar == nil {
				calendar = .current
			}
			updateWeekLabels()
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
			
			if current != nil {
				let components = calendar.dateComponents([.month, .year], from: date)
				
				if  components.month! != current.month || components.year! != current.year {
					(current.month, current.year) = (components.month!, components.year!)
				} else {
					collectionView?.reloadData()
				}
			}
			
			delegate?.calendarViewControllerDateChanged(self)
		}
	}
	
	public var minimumDate: Date? {
		didSet {
			collectionView?.reloadData()
		}
	}
	public var maximumDate: Date? {
		didSet {
			collectionView?.reloadData()
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
	
	private var selectedDay: Day {
		let components = calendar.dateComponents([.day, .month, .year], from: date)
		return Day(calendar: calendar, day: components.day!, month: components.month!, year: components.year!)
	}
	
	private struct Current {
		var month: Int {
			didSet {
				let firstOfMonth = DateComponents(calendar: calendar, year: year, month: month, day: 1).date!
				let range = calendar.range(of: .month, in: .year, for: firstOfMonth)!
				if month > range.last! {
					month = range.first!
					year += 1
				} else if month < range.first! {
					month = range.last!
					year -= 1
				}
			}
		}
		
		var year: Int
		
		private let calendar: Calendar

		init(calendar: Calendar, month: Int, year: Int) {
			self.calendar = calendar
			self.month = month
			self.year = year
		}
		
		
	}
	
	private var current: Current! {
		didSet {
			updateMonthLabel()
			updateDays()
			collectionView.reloadData()
		}
	}
	
	private var days: [Day] = []
	
	public required init?(coder: NSCoder) {
		super.init(nibName: "JBCalendarViewController", bundle: Bundle(for: Self.self))
		commonInit()
	}
	
	public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		commonInit()
	}
	
	public init() {
		super.init(nibName: "JBCalendarViewController", bundle: Bundle(for: Self.self))
		commonInit()
	}
	
	private func commonInit() {
		modalPresentationStyle = .popover
		popoverPresentationController?.delegate = self
		preferredContentSize = CGSize(width: 200, height: 210)
	}
	
	override public func viewDidLoad() {
        super.viewDidLoad()
		
		calendar.locale = self.locale
		
		collectionView.delegate = self
		collectionView.dataSource = self
		collectionView.register(UINib(nibName: "JBCalendarDateCell", bundle: Bundle(for: Self.self)), forCellWithReuseIdentifier: "DateCell")
		
		#if targetEnvironment(macCatalyst)
		view.tintColor = .systemAccent
		#endif
		
		let selectedComponents = calendar.dateComponents([.year, .month], from: date)
		current = Current(calendar: calendar, month: selectedComponents.month!, year: selectedComponents.year!)
		
		let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan(toSelectCells:)))
		collectionView.addGestureRecognizer(pan)
		
		let prevLong = UILongPressGestureRecognizer(target: self, action: #selector(previousMonthButtonTouchDown(_:)))
		prevLong.minimumPressDuration = 0
    
	}
	
	private func updateWeekLabels() {
		var symbols = calendar.veryShortStandaloneWeekdaySymbols
		if (calendar.locale ?? .current).languageCode == "en" {
			symbols = calendar.shortStandaloneWeekdaySymbols.map { String($0.prefix(2)) }
		}
		guard isViewLoaded else { return }
		for (index, symbol) in symbols.enumerated() {
			weekSymbolLabels[index].text = symbol
		}
	}
	
	private func updateDays() {
		let components = DateComponents(calendar: calendar, year: current.year, month: current.month)
		let date = components.date!
		
		let range = calendar.range(of: .day, in: .month, for: date)!
		
		days = range.map { Day(calendar: calendar, day: $0, month: current.month, year: current.year) }
		
		let startDate = calendar.dateInterval(of: .month, for: date)!.start
		let weekday = calendar.dateComponents([.weekday], from: startDate).weekday!
		
		let firstDay = days.first!
		for i in 0 ..< weekday-1 {
			var day = firstDay
			day.day -= i+1
			days.insert(day, at: 0)
		}
		
		let lastDay = days.last!
		let count = calendar.weekdaySymbols.count * 6
		for i in 0 ..< (count-days.count) {
			var day = lastDay
			day.day += i+1
			days.append(day)
		}
	}
	
	private func updateMonthLabel() {
		guard isViewLoaded else { return }
		
		let formatter = DateFormatter()
		formatter.locale = calendar.locale
		formatter.setLocalizedDateFormatFromTemplate("MMM yyyy")
		let components = DateComponents(calendar: calendar, year: current.year, month: current.month)
		monthLabel.text = formatter.string(from: components.date!)
	}
	
	@IBAction private func previousMonthButtonTouchUp(_ sender: Any) {
		timer?.invalidate()
		timer = nil
	}
	
	@IBAction private func selectedDayButtonPressed(_ sender: Any) {
		let components = calendar.dateComponents([.month, .year], from: date)
		let month = components.month!
		let year = components.year!
		current = Current(calendar: calendar, month: month, year: year)
	}
	
	@IBAction private func nextMonthButtonTouchUp(_ sender: Any) {
		timer?.invalidate()
		timer = nil
	}
	
	@IBAction private func previousMonthButtonTouchDown(_ sender: Any) {
		startRepeatingTimer { [weak self] in
			self?.current.month -= 1
		}
	}
	
	private var timer: Timer?
	private func startRepeatingTimer(_ action: @escaping () -> Void) {
		action()
		
		timer = Timer(fire: Date().addingTimeInterval(0.5), interval: 0.25, repeats: true) { timer in
			action()
		}
		RunLoop.main.add(timer!, forMode: .common)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
			if let timer = self.timer {
				timer.invalidate()
				self.timer = Timer(timeInterval: 0.075, repeats: true, block: { timer in
					action()
				})
				RunLoop.main.add(self.timer!, forMode: .common)
			}
		}
	}
	
	@IBAction private func nextMonthButtonTouchDown(_ sender: Any) {
		startRepeatingTimer { [weak self] in
			self?.current.month += 1
		}
	}
		
	private var lastPanChangeDate: Date = Date()
	@objc private func didPan(toSelectCells panGesture: UIPanGestureRecognizer) {
		if panGesture.state == .began {
			collectionView.isUserInteractionEnabled = false
		} else if panGesture.state == .changed, let indexPath = collectionView.indexPathForItem(at: panGesture.location(in: collectionView)) {
			let day = days[indexPath.row]
			let date = DateComponents(calendar: calendar, year: current.year, month: current.month, day: day.day).date!
			let month = calendar.dateComponents([.month], from: date).month!
			
			if month == current.month || -lastPanChangeDate.timeIntervalSinceNow > 0.8 {
				self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
				self.collectionView(collectionView, didSelectItemAt: indexPath)
				
				lastPanChangeDate = Date()
			}
		} else if panGesture.state == .ended {
			collectionView.isUserInteractionEnabled = true
		}
	}
	
}

extension JBCalendarViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return days.count
	}
	
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateCell", for: indexPath) as! JBCalendarDateCell
		let day = days[indexPath.row]
		
		let date = DateComponents(calendar: calendar, year: current.year, month: current.month, day: day.day).date!
		let components = calendar.dateComponents([.day, .month], from: date)
			
		cell.label.text = String(components.day!)
		cell.layer.cornerRadius = 4
		cell.layer.masksToBounds = true
		
		let isSelected = day == selectedDay
		
		let highlightedBackgroundColor: UIColor = day.isToday ? view.tintColor : .systemFill
		cell.backgroundColor = isSelected ? highlightedBackgroundColor : nil
		
		if day.isToday {
			if isSelected {
				cell.label.textColor = .lightLabel
			} else {
				cell.label.textColor = self.view.tintColor
			}
		} else if let minimumDate = usableMinimumDate, date < minimumDate {
			cell.label.textColor = .quaternaryLabel
		} else if let maximumDate = usableMaximumDate, date > maximumDate {
			cell.label.textColor = .quaternaryLabel
		} else if components.month == current.month {
			cell.label.textColor = .label
		} else {
			cell.label.textColor = .tertiaryLabel
		}
		
		return cell
	}
	
	public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		let numberOfItems = collectionView.numberOfItems(inSection: 0)
		
		let spacing = (collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing * CGFloat(numberOfItems-1)
		let width = (self.collectionView.frame.width - spacing) / CGFloat(calendar.weekdaySymbols.count)
		let height = (self.collectionView.frame.height - spacing) / CGFloat(6)
		
		return CGSize(width: width, height: height)
	}
	
	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let day = days[indexPath.row]
		
		var components = calendar.dateComponents([.timeZone, .year, .month, .day, .hour, .minute, .second, .nanosecond], from: self.date)
		components.day = day.day
		components.month = day.month
		components.year = day.year
		let newDate = calendar.date(from: components)!
		
		if let minimumDate = usableMinimumDate, newDate < minimumDate {
			return
		} else if let maximumDate = usableMaximumDate, newDate > maximumDate {
			return
		}
		
		collectionView.reloadData()
		
		self.date = newDate
	}
	
	public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		collectionView.reloadData()
	}
	
}

extension JBCalendarViewController: UIPopoverPresentationControllerDelegate {
	public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}
	
	public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
		delegate?.calendarViewControllerWillDismiss(self)
		print("final date:", date)
	}
	
	public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		delegate?.calendarViewControllerDidDismiss(self)
	}
}
