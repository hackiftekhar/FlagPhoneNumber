//
//  FlagPhoneNumberTextField.swift
//  FlagPhoneNumber
//
//  Created by Aurélien Grifasi on 06/08/2017.
//  Copyright (c) 2017 Aurélien Grifasi. All rights reserved.
//

import UIKit

open class FPNTextField: UITextField {

	/// The size of the flag button
    @objc open var flagButtonSize: CGSize = CGSize(width: 40, height: 40) {
        didSet {
            layoutIfNeeded()
        }
    }

    private var flagWidthConstraint: NSLayoutConstraint?
    private var flagHeightConstraint: NSLayoutConstraint?

    private let leftContainerView = UIView()

	/// The size of the leftView
	private var leftViewSize: CGSize {
        let width = flagButtonSize.width + getWidth(text: phoneCodeTextField.text!)
		let height = bounds.height

		return CGSize(width: width, height: height)
	}

	private var phoneCodeTextField: UITextField = UITextField()

	private lazy var phoneUtil: NBPhoneNumberUtil = NBPhoneNumberUtil()
	private var nbPhoneNumber: NBPhoneNumber?
	private var formatter: NBAsYouTypeFormatter?

	open var flagButton: FPNButton = FPNButton()

	open override var font: UIFont? {
		didSet {
			phoneCodeTextField.font = font
		}
	}

	open override var textColor: UIColor? {
		didSet {
			phoneCodeTextField.textColor = textColor
		}
	}

    @objc open var pickerFont: UIFont? {
        didSet {
            pickerView.pickerFont = pickerFont
        }
    }
    @objc open var pickerTextColor: UIColor? {
        didSet {
            pickerView.pickerTextColor = pickerTextColor
        }
    }

	/// Present in the placeholder an example of a phone number according to the selected country code.
	/// If false, you can set your own placeholder. Set to true by default.
	@objc open var hasPhoneNumberExample: Bool = true {
		didSet {
			if hasPhoneNumberExample == false {
				placeholder = nil
			}
			updatePlaceholder()
		}
	}

	open var countryRepository = FPNCountryRepository()

	open var selectedCountry: FPNCountry? {
		didSet {
			updateUI()
		}
	}

	/// If set, a search button appears in the picker inputAccessoryView to present a country search view controller
	@IBOutlet public var parentViewController: UIViewController?

	/// Input Accessory View for the texfield
	@objc open var textFieldInputAccessoryView: UIView?

	open lazy var pickerView: FPNCountryPicker = FPNCountryPicker()

	init() {
		super.init(frame: .zero)

		setup()
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)

		setup()
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		setup()
	}

	deinit {
		parentViewController = nil
	}

	private func setup() {
		setupFlagButton()
		setupPhoneCodeTextField()
		setupLeftView()

		keyboardType = .numberPad
		autocorrectionType = .no
		addTarget(self, action: #selector(didEditText), for: .editingChanged)
		addTarget(self, action: #selector(displayNumberKeyBoard), for: .touchDown)

		if let regionCode = Locale.current.regionCode, let countryCode = FPNCountryCode(rawValue: regionCode) {
			setFlag(countryCode: countryCode)
		} else {
			setFlag(countryCode: FPNCountryCode.US)
		}
	}

	private func setupFlagButton() {
		flagButton.accessibilityLabel = "flagButton"
		flagButton.addTarget(self, action: #selector(displayCountries), for: .touchUpInside)
		flagButton.translatesAutoresizingMaskIntoConstraints = false
	}

	private func setupPhoneCodeTextField() {
		phoneCodeTextField.font = font
		phoneCodeTextField.isUserInteractionEnabled = false
		phoneCodeTextField.translatesAutoresizingMaskIntoConstraints = false
	}

	private func setupLeftView() {

        leftContainerView.addSubview(flagButton)
        leftContainerView.addSubview(phoneCodeTextField)

		leftView = leftContainerView
		leftViewMode = .always

        if #available(iOS 9.0, *) {
			phoneCodeTextField.semanticContentAttribute = .forceLeftToRight
		} else {
			// Fallback on earlier versions
		}

        flagWidthConstraint = NSLayoutConstraint(item: flagButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: flagButtonSize.width)
        flagHeightConstraint = NSLayoutConstraint(item: flagButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: flagButtonSize.height)

        flagWidthConstraint?.isActive = true
        flagHeightConstraint?.isActive = true

        //center
        NSLayoutConstraint(item: flagButton, attribute: .centerY, relatedBy: .equal, toItem: leftContainerView, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: phoneCodeTextField, attribute: .centerY, relatedBy: .equal, toItem: leftContainerView, attribute: .centerY, multiplier: 1, constant: 0).isActive = true

        //leading trailing
        NSLayoutConstraint(item: flagButton, attribute: .leading, relatedBy: .equal, toItem: leftContainerView, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: phoneCodeTextField, attribute: .trailing, relatedBy: .equal, toItem: leftContainerView, attribute: .trailing, multiplier: 1, constant: 0).isActive = true

        //difference
        NSLayoutConstraint(item: phoneCodeTextField, attribute: .leading, relatedBy: .equal, toItem: flagButton, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
    }

    open override func updateConstraints() {
        super.updateConstraints()

        flagWidthConstraint?.constant = flagButtonSize.width
        flagHeightConstraint?.constant = flagButtonSize.height
    }

    open override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
		let size = leftViewSize
		let width: CGFloat = min(bounds.size.width, size.width)
		let height: CGFloat = min(bounds.size.height, size.height)
		let newRect: CGRect = CGRect(x: bounds.minX, y: bounds.minY, width: width, height: height)

		return newRect
	}

	@objc private func displayNumberKeyBoard() {
        tintColor = .gray
        inputView = nil
        inputAccessoryView = textFieldInputAccessoryView
        reloadInputViews()
	}

	@objc private func displayCountries() {
        pickerView.setup(repository: countryRepository)
        
        tintColor = .clear
        inputView = pickerView
        inputAccessoryView = getToolBar(with: getCountryListBarButtonItems())
        reloadInputViews()
        becomeFirstResponder()
        
        pickerView.didSelect = { [weak self] country in
            self?.fpnDidSelect(country: country)
        }
        
        if let selectedCountry = selectedCountry {
            pickerView.setCountry(selectedCountry.code)
        } else if let regionCode = Locale.current.regionCode, let countryCode = FPNCountryCode(rawValue: regionCode) {
            pickerView.setCountry(countryCode)
        } else if let firstCountry = countryRepository.countries.first {
            pickerView.setCountry(firstCountry.code)
        }
	}

    @objc private func displayAlphabeticKeyBoard() {
        showSearchController()
    }

	@objc private func dismissCountries() {
		resignFirstResponder()
		inputView = nil
		inputAccessoryView = nil
		reloadInputViews()
	}

	private func fpnDidSelect(country: FPNCountry) {
		(delegate as? FPNTextFieldDelegate)?.fpnDidSelectCountry(name: country.name, dialCode: country.phoneCode, code: country.code.rawValue)
		selectedCountry = country
	}

	// - Public

	/// Get the current formatted phone number
	open func getFormattedPhoneNumber(format: FPNFormat) -> String? {
		return try? phoneUtil.format(nbPhoneNumber, numberFormat: convert(format: format))
	}

	/// For Objective-C, Get the current formatted phone number
	@objc open func getFormattedPhoneNumber(format: Int) -> String? {
		if let formatCase = FPNFormat(rawValue: format) {
			return try? phoneUtil.format(nbPhoneNumber, numberFormat: convert(format: formatCase))
		}
		return nil
	}

    @objc open var hasValidPhoneNumber : Bool {
        return getRawPhoneNumber() != nil
    }

	/// Get the current raw phone number
	@objc open func getRawPhoneNumber() -> String? {
		let phoneNumber = getFormattedPhoneNumber(format: .E164)
		var nationalNumber: NSString?

		phoneUtil.extractCountryCode(phoneNumber, nationalNumber: &nationalNumber)

		return nationalNumber as String?
	}

	/// Set directly the phone number. e.g "+33612345678"
	@objc open func set(phoneNumber: String) {

		var cleanedPhoneNumber: String = clean(string: phoneNumber)

        //1st try to get valid number
        var validPhoneNumber = getValidNumber(phoneNumber: cleanedPhoneNumber)

        //If didn't get then adding selected country prefix and retring again
        if validPhoneNumber == nil, cleanedPhoneNumber.hasPrefix("+") == false, let dialCode = selectedCountry?.phoneCode {
            cleanedPhoneNumber = clean(string: "\(dialCode) \(phoneNumber)")
            validPhoneNumber = getValidNumber(phoneNumber: cleanedPhoneNumber)
        }

        nbPhoneNumber = validPhoneNumber

		if let validPhoneNumber = validPhoneNumber {

			if validPhoneNumber.italianLeadingZero {
				text = "0\(validPhoneNumber.nationalNumber.stringValue)"
			} else {
				text = validPhoneNumber.nationalNumber.stringValue
			}
			setFlag(countryCode: FPNCountryCode(rawValue: phoneUtil.getRegionCode(for: validPhoneNumber))!)
        } else if let dialCode = selectedCountry?.phoneCode {

            let codePhoneNumber = clean(string: "\(dialCode) \(phoneNumber)")
            
            if let inputString = formatter?.inputString(codePhoneNumber) {
                text = remove(dialCode: dialCode, in: inputString)
            }
        } else {
            text = cleanedPhoneNumber
        }
	}

	/// Set the country image according to country code. Example "FR"
	open func setFlag(countryCode: FPNCountryCode) {
		let countries = countryRepository.countries

		for country in countries {
			if country.code == countryCode {
				return fpnDidSelect(country: country)
			}
		}
	}

	/// Set the country image according to country code. Example "FR"
	@objc open func setFlag(key: FPNOBJCCountryKey) {
		if let code = FPNOBJCCountryCode[key], let countryCode = FPNCountryCode(rawValue: code) {

			setFlag(countryCode: countryCode)
		}
	}

	/// Set the country list excluding the provided countries
	open func setCountries(excluding countries: [FPNCountryCode]) {
		countryRepository.setup(without: countries)

		if let selectedCountry = selectedCountry, countryRepository.countries.contains(selectedCountry) {
			fpnDidSelect(country: selectedCountry)
		} else if let country = countryRepository.countries.first {
			fpnDidSelect(country: country)
		}
	}

	/// Set the country list including the provided countries
	open func setCountries(including countries: [FPNCountryCode]) {
		countryRepository.setup(with: countries)

		if let selectedCountry = selectedCountry, countryRepository.countries.contains(selectedCountry) {
			fpnDidSelect(country: selectedCountry)
		} else if let country = countryRepository.countries.first {
			fpnDidSelect(country: country)
		}
	}

	/// Set the country list excluding the provided countries
	@objc open func setCountries(excluding countries: [Int]) {
		let countryCodes: [FPNCountryCode] = countries.compactMap({ index in
			if let key = FPNOBJCCountryKey(rawValue: index), let code = FPNOBJCCountryCode[key], let countryCode = FPNCountryCode(rawValue: code) {
				return countryCode
			}
			return nil
		})

		countryRepository.setup(without: countryCodes)
	}

	/// Set the country list including the provided countries
	@objc open func setCountries(including countries: [Int]) {
		let countryCodes: [FPNCountryCode] = countries.compactMap({ index in
			if let key = FPNOBJCCountryKey(rawValue: index), let code = FPNOBJCCountryCode[key], let countryCode = FPNCountryCode(rawValue: code) {
				return countryCode
			}
			return nil
		})

		countryRepository.setup(with: countryCodes)
	}

	// Private

	@objc private func didEditText() {
		if let phoneCode = selectedCountry?.phoneCode, let number = text {
			var cleanedPhoneNumber = clean(string: "\(phoneCode) \(number)")

			if let validPhoneNumber = getValidNumber(phoneNumber: cleanedPhoneNumber) {
				nbPhoneNumber = validPhoneNumber

				cleanedPhoneNumber = "+\(validPhoneNumber.countryCode.stringValue)\(validPhoneNumber.nationalNumber.stringValue)"

				if let inputString = formatter?.inputString(cleanedPhoneNumber) {
					text = remove(dialCode: phoneCode, in: inputString)
				}
				(delegate as? FPNTextFieldDelegate)?.fpnDidValidatePhoneNumber(textField: self, isValid: true)
			} else {
				nbPhoneNumber = nil

                if let inputString = formatter?.inputString(cleanedPhoneNumber) {
                    text = remove(dialCode: phoneCode, in: inputString)
                }

                (delegate as? FPNTextFieldDelegate)?.fpnDidValidatePhoneNumber(textField: self, isValid: false)
			}
		}
	}

	private func convert(format: FPNFormat) -> NBEPhoneNumberFormat {
		switch format {
		case .E164:
			return NBEPhoneNumberFormat.E164
		case .International:
			return NBEPhoneNumberFormat.INTERNATIONAL
		case .National:
			return NBEPhoneNumberFormat.NATIONAL
		case .RFC3966:
			return NBEPhoneNumberFormat.RFC3966
		}
	}

	private func updateUI() {
		if let countryCode = selectedCountry?.code {
			formatter = NBAsYouTypeFormatter(regionCode: countryCode.rawValue)
		}

		flagButton.setImage(selectedCountry?.flag, for: .normal)

		if let phoneCode = selectedCountry?.phoneCode {
			phoneCodeTextField.text = phoneCode
		}

		if hasPhoneNumberExample == true {
			updatePlaceholder()
		}
		didEditText()
	}

	private func clean(string: String) -> String {
		var allowedCharactersSet = CharacterSet.decimalDigits

		allowedCharactersSet.insert("+")

		return string.components(separatedBy: allowedCharactersSet.inverted).joined(separator: "")
	}

	private func getWidth(text: String) -> CGFloat {
		if let font = phoneCodeTextField.font {
			let fontAttributes = [NSAttributedString.Key.font: font]
			let size = (text as NSString).size(withAttributes: fontAttributes)

			return size.width.rounded(.up)
		} else {
			phoneCodeTextField.sizeToFit()

			return phoneCodeTextField.frame.size.width.rounded(.up)
		}
	}

	private func getValidNumber(phoneNumber: String) -> NBPhoneNumber? {
		guard let countryCode = selectedCountry?.code else { return nil }

		do {
			let parsedPhoneNumber: NBPhoneNumber = try phoneUtil.parse(phoneNumber, defaultRegion: countryCode.rawValue)
			let isValid = phoneUtil.isValidNumber(parsedPhoneNumber)

			return isValid ? parsedPhoneNumber : nil
		} catch _ {
			return nil
		}
	}

	private func remove(dialCode: String, in phoneNumber: String) -> String {
		return phoneNumber.replacingOccurrences(of: "\(dialCode) ", with: "").replacingOccurrences(of: "\(dialCode)", with: "")
	}

    private func showSearchController() {
        
        let searchCountryViewController = FPNCountryListViewController(style: .grouped)
        let navigationViewController = UINavigationController(rootViewController: searchCountryViewController)
        searchCountryViewController.pickerFont = pickerFont
        searchCountryViewController.pickerTextColor = pickerTextColor
        searchCountryViewController.setup(repository: countryRepository)
        searchCountryViewController.didSelect = { [weak self] country in
            self?.setFlag(countryCode: country.code)
            self?.pickerView.setCountry(country.code)
        }
        
        parentViewController?.present(navigationViewController, animated: true, completion: nil)
    }

	private func getToolBar(with items: [UIBarButtonItem]) -> UIToolbar {
		let toolbar: UIToolbar = UIToolbar()

		toolbar.barStyle = UIBarStyle.default
		toolbar.items = items
		toolbar.sizeToFit()

		return toolbar
	}

	private func getCountryListBarButtonItems() -> [UIBarButtonItem] {
		let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissCountries))

		doneButton.accessibilityLabel = "doneButton"

        if parentViewController != nil {
            let searchButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.search, target: self, action: #selector(displayAlphabeticKeyBoard))

            searchButton.accessibilityLabel = "searchButton"

            return [searchButton, space, doneButton]
        }

		return [space, doneButton]
	}

	private func updatePlaceholder() {
		if let countryCode = selectedCountry?.code {
			do {
				let example = try phoneUtil.getExampleNumber(countryCode.rawValue)
				let phoneNumber = "+\(example.countryCode.stringValue)\(example.nationalNumber.stringValue)"

				if let inputString = formatter?.inputString(phoneNumber) {
					placeholder = remove(dialCode: "+\(example.countryCode.stringValue)", in: inputString)
				} else {
					placeholder = nil
				}
			} catch _ {
				placeholder = nil
			}
		} else {
			placeholder = nil
		}
	}
}
