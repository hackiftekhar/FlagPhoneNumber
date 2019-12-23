//
//  FPNCountryListViewController.swift
//  FlagPhoneNumber
//
//  Created by Aurélien Grifasi on 06/08/2017.
//  Copyright (c) 2017 Aurélien Grifasi. All rights reserved.
//

import UIKit

open class CountryCell : UITableViewCell {

    fileprivate let flagImageView = UIImageView(frame: CGRect(x: 15, y: 12, width: 20, height: 20))
    fileprivate let countryCodeLabel = UILabel(frame: CGRect(x: 55, y: 11, width: 40, height: 22))
    fileprivate let countryNameLabel = UILabel(frame: CGRect(x: 115, y: 13, width: 200, height: 18))

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        flagImageView.contentMode = .scaleToFill
        flagImageView.layer.cornerRadius = 10
        flagImageView.layer.masksToBounds = true

        countryNameLabel.autoresizingMask = [.flexibleWidth]
        countryNameLabel.lineBreakMode = .byTruncatingMiddle
        
        self.contentView.addSubview(flagImageView)
        self.contentView.addSubview(countryCodeLabel)
        self.contentView.addSubview(countryNameLabel)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

open class FPNCountryListViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate {

	open var repository: FPNCountryRepository?
	open var searchController: UISearchController = UISearchController(searchResultsController: nil)
	open var didSelect: ((FPNCountry) -> Void)?

	var results: [FPNCountry]?

    open var pickerFont: UIFont?
    open var pickerTextColor: UIColor?

	override open func viewDidLoad() {
		super.viewDidLoad()

		tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
		initSearchBarController()
        
        tableView.register(CountryCell.self, forCellReuseIdentifier: "CountryCell")
	}

	open func setup(repository: FPNCountryRepository) {
		self.repository = repository
	}

	private func initSearchBarController() {
		searchController.searchResultsUpdater = self
		searchController.delegate = self

		if #available(iOS 9.1, *) {
			searchController.obscuresBackgroundDuringPresentation = false
		} else {
			// Fallback on earlier versions
		}

		if #available(iOS 11.0, *) {
			navigationItem.searchController = searchController
			navigationItem.hidesSearchBarWhenScrolling = false
		} else {
			searchController.dimsBackgroundDuringPresentation = false
			searchController.hidesNavigationBarDuringPresentation = true
			searchController.definesPresentationContext = true

			//				searchController.searchBar.sizeToFit()
			tableView.tableHeaderView = searchController.searchBar
		}
		definesPresentationContext = true
	}

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        searchController.isActive = true
    }

    @objc private func dismissController() {
        dismiss(animated: true, completion: nil)
    }

	private func getItem(at indexPath: IndexPath) -> FPNCountry {
		if searchController.isActive && results != nil && results!.count > 0 {
			return results![indexPath.row]
		} else {
			return repository!.countries[indexPath.row]
		}
	}

	override open func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if searchController.isActive {
			if let count = searchController.searchBar.text?.count, count > 0 {
				return results?.count ?? 0
			}
		}
		return repository?.countries.count ?? 0
	}

	override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath) as! CountryCell
        
        cell.countryCodeLabel.font = pickerFont ?? UIFont.systemFont(ofSize: 14)
        cell.countryNameLabel.font = pickerFont ?? UIFont.systemFont(ofSize: 14)

        cell.countryCodeLabel.textColor = pickerTextColor ?? UIColor.black
        cell.countryNameLabel.textColor = pickerTextColor ?? UIColor.black

		let country = getItem(at: indexPath)

        cell.flagImageView.image = country.flag
        cell.countryCodeLabel.text = country.phoneCode
        cell.countryNameLabel.text = country.name

		return cell
	}

	override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let country = getItem(at: indexPath)

		tableView.deselectRow(at: indexPath, animated: true)

		didSelect?(country)

		searchController.isActive = false
		searchController.searchBar.resignFirstResponder()
		dismiss(animated: true, completion: nil)
	}

	// UISearchResultsUpdating

	open func updateSearchResults(for searchController: UISearchController) {
		guard let countries = repository?.countries else { return }

		if countries.isEmpty {
			results?.removeAll()
			return
		} else if searchController.searchBar.text == "" {
			results?.removeAll()
			tableView.reloadData()
			return
		}

		if let searchText = searchController.searchBar.text, searchText.count > 0 {
			results = countries.filter({(item: FPNCountry) -> Bool in
				if item.name.lowercased().range(of: searchText.lowercased()) != nil {
					return true
				} else if item.code.rawValue.lowercased().range(of: searchText.lowercased()) != nil {
					return true
				} else if item.phoneCode.lowercased().range(of: searchText.lowercased()) != nil {
					return true
				}
				return false
			})
		}
		tableView.reloadData()
	}

	// UISearchControllerDelegate

	open func willDismissSearchController(_ searchController: UISearchController) {
		results?.removeAll()
	}

    open func didDismissSearchController(_ searchController: UISearchController) {
        dismissController()
    }
}
