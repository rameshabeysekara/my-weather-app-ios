//
//  Screen2ViewController.swift
//  lab_03
//
//  Created by Ramesh Abeysekara on 2023-11-30.
//

import UIKit

class Screen2ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var items: [Cities] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    @IBAction func backTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
}

extension Screen2ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cityCell", for: indexPath)
        let item = items[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = item.cityName
        content.secondaryText = item.temperature
        if let originalIcon = item.icon {
            let redTintedImage = originalIcon.withTintColor(.red)
            content.image = redTintedImage
        }
        cell.contentConfiguration = content
        
        return cell
    }
}

extension Screen2ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadRows(at: [indexPath], with: .automatic)
        clickItem(at: indexPath)
    }
    
    private func clickItem(at indexPath: IndexPath){
        let alertController = UIAlertController(title: "City Actions", message: "Do you want to remove this city from list?", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Remove", style: .default, handler: { action in
            self.items.remove(at: indexPath.row)
            self.tableView.reloadData()
        }))
        
        self.present(alertController, animated: true)
    }
}

struct Cities {
    let cityName: String
    let temperature: String
    let icon: UIImage?
}
