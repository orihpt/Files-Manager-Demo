//
//  TableViewController.swift
//  FilesManagerDemo
//
//  Created by אורי האופטמן on 22/12/2020.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

typealias UrlLink = String

extension UrlLink {
    var url: URL {
        var url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        url.appendPathComponent(self)
        return url
    }
}

struct UserData: Encodable, Decodable {
    var names: [UrlLink] = [] {
        didSet {
            try! UserDefaults.standard.setToObject(names, forKey: "names")
        }
    }
}

class TableViewController: UITableViewController, UIDocumentPickerDelegate {
    
    var names: [UrlLink] = [] {
        willSet {
            let data = UserData(names: newValue)
            try! UserDefaults.standard.setToObject(data, forKey: "names")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let names = try? UserDefaults.standard.getToObject(forKey: "names", castTo: UserData.self).names {
            self.names = names
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func urlForFilename(_ filename: String) -> URL {
        var url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        url.appendPathComponent(filename)
        return url
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
            let removedName = self.names.remove(at: indexPath.row)
            do {
                try FileManager.default.removeItem(atPath: removedName.url.path)
            } catch let err {
                print("Error while trying to remove the file \(err)")
            }
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return names.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

        cell.textLabel?.text = names[indexPath.row]
        
        if FileManager.default.fileExists(atPath: names[indexPath.row].url.path) {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = .none
        }

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
        share(url: self.names[indexPath.row].url)
    }
    
    func storeAndShare(withURL url: URL) {

        let directoryURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var newURL = directoryURL.appendingPathComponent(url.lastPathComponent)
        
        var index = 1
        let originalNewURL = newURL
        while FileManager.default.fileExists(atPath: newURL.path) {
            newURL = originalNewURL
            let comp: NSString = newURL.lastPathComponent as NSString
            newURL.deleteLastPathComponent()
            let newName: String = "\(comp.deletingPathExtension) \(index).\(comp.pathExtension)"
            newURL.appendPathComponent(newName)
            index = index + 1
        }
        
        do {
            try FileManager.default.copyItem(at: url, to: newURL)
            DispatchQueue.main.async { [self] in
                names.append(newURL.lastPathComponent)
                tableView.insertRows(at: [IndexPath(row: names.count - 1, section: 0)], with: .automatic)
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
