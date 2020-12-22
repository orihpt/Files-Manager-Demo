//
//  TableViewController.swift
//  FilesManagerDemo
//
//  Created by אורי האופטמן on 22/12/2020.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

struct UserData: Encodable, Decodable {
    var urls: [URL] = [] {
        didSet {
            try! UserDefaults.standard.setToObject(urls, forKey: "urls")
        }
    }
}

class TableViewController: UITableViewController, UIDocumentPickerDelegate {
    
    var urls: [URL] = [] {
        willSet {
            let data = UserData(urls: newValue)
            try! UserDefaults.standard.setToObject(data, forKey: "userdata")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let urls = try? UserDefaults.standard.getToObject(forKey: "userdata", castTo: UserData.self).urls {
            self.urls = urls
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    @IBAction func newButtonPressed(_ sender: Any) {
        let types = UTType(tag: "pdf", tagClass: .filenameExtension, conformingTo: nil)!
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [types])
        controller.delegate = self
        self.present(controller, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            self.storeAndShare(withURL: url)
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.urls.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return urls.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

        cell.textLabel?.text = urls[indexPath.row].localizedName

        return cell
    }
    
    lazy var documentInteractionController: UIDocumentInteractionController = {
        let vc = UIDocumentInteractionController()
        vc.delegate = self
        return vc
    }()
    
    func getSelf() -> TableViewController {
        return self
    }
    
    func share(url: URL) {
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentPreview(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        share(url: self.urls[indexPath.row])
    }
    
    func storeAndShare(withURL url: URL) {

        let directoryURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        var newURL = directoryURL.appendingPathComponent(url.lastPathComponent)
        
        var index = 1
        let originalNewURL = newURL
        while FileManager.default.fileExists(atPath: newURL.path) {
            newURL = originalNewURL
            var comp = newURL.lastPathComponent
            newURL.deleteLastPathComponent()
            comp = "\(comp) (\(index))"
            newURL.appendPathComponent(comp)
            index = index + 1
        }
        
        do {
            try FileManager.default.copyItem(at: url, to: newURL)
            DispatchQueue.main.async {
                self.urls.append(newURL)
                self.share(url: newURL)
                self.tableView.reloadData()
            }
        } catch {
            print("ERROR: \(error).")
        }
    }

}

extension TableViewController: UIDocumentInteractionControllerDelegate {
    /// If presenting atop a navigation stack, provide the navigation controller in order to animate in a manner consistent with the rest of the platform
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        guard let navVC = self.navigationController else {
            return self
        }
        return navVC
    }
}
extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}
