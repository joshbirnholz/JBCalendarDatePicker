//
//  UIColor+SystemAccent.swift
//  CalendarDatePickerViewController
//
//  Created by Josh Birnholz on 28/10/2019.
//  Copyright © 2019 Josh Birnholz. All rights reserved.
//


import UIKit

extension UIColor {
	
	#if targetEnvironment(macCatalyst)
	static var systemAccent: UIColor {
		let hasAccentSet = UserDefaults.standard.object(forKey: "AppleAccentColor") != nil
		let systemAccentColor = UserDefaults.standard.integer(forKey: "AppleAccentColor")
		var returnColor: UIColor = UIColor { traitCollection in
				traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.008315349929, green: 0.3450804651, blue: 0.817365706, alpha: 1) : #colorLiteral(red: 0.01329958253, green: 0.3846624196, blue: 0.8779004216, alpha: 1)
		}
		if hasAccentSet {
			switch systemAccentColor {
				case -1:
					returnColor = UIColor { traitCollection in
							traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.4039281607, green: 0.403850317, blue: 0.4124818146, alpha: 1) : #colorLiteral(red: 0.5019147992, green: 0.5019902587, blue: 0.5018982291, alpha: 1)
					}
				case 0:
					returnColor = UIColor { traitCollection in
							traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.82002002, green: 0.2045214176, blue: 0.2204136252, alpha: 1) : #colorLiteral(red: 0.7370213866, green: 0.1443678439, blue: 0.1633504629, alpha: 1)
					}
				case 1:
					returnColor = UIColor { traitCollection in
							traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.7512640357, green: 0.3605512679, blue: 0.01273573376, alpha: 1) : #colorLiteral(red: 0.8462041616, green: 0.4178547263, blue: 0.05405366421, alpha: 1)
					}
				case 2:
					returnColor = UIColor { traitCollection in
							traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.8009095192, green: 0.5611655712, blue: 0.05494389683, alpha: 1) : #colorLiteral(red: 0.8690621257, green: 0.6199508309, blue: 0.07889743894, alpha: 1)
					}
				case 3:
					returnColor = UIColor { traitCollection in
							traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.2549478412, green: 0.5663680434, blue: 0.1645001471, alpha: 1) : #colorLiteral(red: 0.3048421741, green: 0.6298194528, blue: 0.1963118315, alpha: 1)
					}
				case 5:
					returnColor = UIColor { traitCollection in
						traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.500952661, green: 0.1951716244, blue: 0.5008149147, alpha: 1) : #colorLiteral(red: 0.4900261164, green: 0.1631549001, blue: 0.4976372719, alpha: 1)
				}
				case 6:
					returnColor = UIColor { traitCollection in
							traitCollection.userInterfaceStyle == .dark ? #colorLiteral(red: 0.7823504806, green: 0.1956582665, blue: 0.4722630978, alpha: 1) : #colorLiteral(red: 0.8491325974, green: 0.2301979959, blue: 0.5240355134, alpha: 1)
					}
				default:
					break
			}
		}
		return returnColor
	}
	#endif

	static let lightLabel = UIColor { traitCollection in
		if traitCollection.userInterfaceStyle == .dark {
			return .label
		} else {
			return .systemBackground
		}
	}
}
