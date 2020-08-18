//
//  FPNCountryRepository.swift
//  FlagPhoneNumber
//
//  Created by Aurelien on 21/11/2019.
//

import Foundation

open class FPNCountryRepository {

    open var countries: [FPNCountry] = []

    private static var countries: [FPNCountry] = {
        let bundle: Bundle = Bundle.FlagPhoneNumber()
        let resource: String = "countryCodes"

        if let jsonPath = bundle.path(forResource: resource, ofType: "json"),
            let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
            let jsonObjects = try? JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [[String:Any]] {

            var countries = [FPNCountry]()

            for countryObj in jsonObjects {
                if let code = countryObj["code"] as? String, let phoneCode = countryObj["dial_code"] as? String, let name = countryObj["name"] as? String {
                    let country = FPNCountry(code: code, name: Locale.current.localizedString(forRegionCode: code) ?? name, phoneCode: phoneCode)
                    countries.append(country)
                }
            }
            return countries.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending })
        }

        return []
    }()

    public init() {
        countries = FPNCountryRepository.countries
    }

    private func getAllCountries(excluding countryCodes: [FPNCountryCode]) -> [FPNCountry] {
        var allCountries = FPNCountryRepository.countries

        for countryCode in countryCodes {
            allCountries.removeAll(where: { (country: FPNCountry) -> Bool in
                return country.code == countryCode
            })
        }
        return allCountries
    }

    private func getAllCountries(equalTo countryCodes: [FPNCountryCode]) -> [FPNCountry] {
        let allCountries = FPNCountryRepository.countries
        var countries = [FPNCountry]()

        for countryCode in countryCodes {
            for country in allCountries {
                if country.code == countryCode {
                    countries.append(country)
                }
            }
        }
        return countries
    }

    open func setup(with countryCodes: [FPNCountryCode]) {
        countries = getAllCountries(equalTo: countryCodes)
    }

    open func setup(without countryCodes: [FPNCountryCode]) {
        countries = getAllCountries(excluding: countryCodes)
    }

}
