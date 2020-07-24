//
//  FPNCountryListViewController.swift
//  FlagPhoneNumber
//
//  Created by Aurélien Grifasi on 06/08/2017.
//  Copyright (c) 2017 Aurélien Grifasi. All rights reserved.
//

import UIKit

open class FPNCountryListViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate {

    open var repository: FPNCountryRepository?
    open var showCountryPhoneCode: Bool = true
    open var searchController: UISearchController = UISearchController(searchResultsController: nil)
    open var didSelect: ((FPNCountry) -> Void)?

    var results: [FPNCountry]?

    lazy var dataSource: [[FPNCountry]] = {
        return sortCountriesByGroups(countriesSource: currentCountriesList)
    }()

    var currentCountriesList: [FPNCountry]  {
        if searchController.isActive && results != nil && results!.count > 0 {
            return results!
        } else {
            return repository!.countries
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        initSearchBarController()
    }

    open func setup(repository: FPNCountryRepository) {
        self.repository = repository
    }

    private func sortCountriesByGroups(countriesSource: [FPNCountry]) -> [[FPNCountry]] {
        var countries: [String: [FPNCountry]] = [String: [FPNCountry]]()

        countriesSource.forEach { country in
            guard let firstLetter = country.name.first else { return }
            let firstLetterString = String(firstLetter).uppercased()
            if let existingArray = countries[firstLetterString] {
                countries[firstLetterString]?.append(country)
            } else {
                countries[firstLetterString] = [country]
            }
        }

        let sortedKeys = Array(countries.keys).sorted(by: <)
        var resultArray: [[FPNCountry]] = [[FPNCountry]]()
        sortedKeys.forEach { key in
            guard let countriesArray = countries[key] else { return }
            let sortedCountries = countriesArray.sorted { country1, country2 -> Bool in
                return country1.name < country2.name
            }
            resultArray.append(sortedCountries)
        }

        return resultArray
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

            //                searchController.searchBar.sizeToFit()
            tableView.tableHeaderView = searchController.searchBar
        }
        definesPresentationContext = true
    }

    private func getItem(at indexPath: IndexPath) -> FPNCountry {
        if searchController.isActive && results != nil && results!.count > 0 {
            return results![indexPath.row]
        } else {
            return repository!.countries[indexPath.row]
        }
    }

    open override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        var indexSet: Set<String> = Set<String>()
        currentCountriesList.forEach { country in
            guard let firstLetter = country.name.first else { return }
            let firstLetterString = String(firstLetter).uppercased()
            indexSet.insert(firstLetterString)
        }
        return Array(indexSet).sorted(by: < )
    }

    open override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = dataSource[section]
        return section.count
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        let section = dataSource[indexPath.section]
        let country = section[indexPath.row]

        cell.imageView?.image = country.flag
        cell.textLabel?.text = country.name

        if showCountryPhoneCode {
            cell.detailTextLabel?.text = country.phoneCode
        }

        return cell
    }

    open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    open override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let country = dataSource[indexPath.section][indexPath.row]

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
        dataSource = sortCountriesByGroups(countriesSource: currentCountriesList)
        tableView.reloadData()
    }

    // UISearchControllerDelegate

    open func willDismissSearchController(_ searchController: UISearchController) {
        results?.removeAll()
    }
}
