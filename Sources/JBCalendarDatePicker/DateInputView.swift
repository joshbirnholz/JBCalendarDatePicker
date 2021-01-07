//
//  DateInputView.swift
//  CalendarDatePickerViewController
//
//  Created by Josh Birnholz on 10/29/19.
//  Copyright © 2019 Josh Birnholz. All rights reserved.
//

#if canImport(UIKit)
import UIKit

protocol DateInputViewDelegate: UIResponder, UIKeyInput {
	
}

class DateInputView: UIView, UIKeyInput {
	
	weak var delegate: DateInputViewDelegate?
	
	override func becomeFirstResponder() -> Bool {
		print(type(of: self), #function)
		let value = super.becomeFirstResponder()
		print(type(of: self), "is first responder: \(self.isFirstResponder)")
		return value
	}
	
	override func resignFirstResponder() -> Bool {
		print(type(of: self), #function)
		return delegate?.resignFirstResponder() ?? super.resignFirstResponder()
	}
	
	override var canBecomeFirstResponder: Bool {
		return true
	}
	
	// MARK: UIKeyInput
	
	var hasText: Bool {
		return delegate?.hasText ?? false
	}
	
	func insertText(_ text: String) {
		delegate?.insertText(text)
	}
	
	func deleteBackward() {
		delegate?.deleteBackward()
	}
	
	// MARK: UITextInputTraits
	
	// this doesn't seem to work for some reason.
	private var keyboardType: UIKeyboardType {
		return .numberPad
	}

}
#endif
