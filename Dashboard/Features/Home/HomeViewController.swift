//
//  ViewController.swift
//  Dashboard
//
//  Created by Patrick Gatewood on 2/18/19.
//  Copyright © 2019 Patrick Gatewood. All rights reserved.
//

import UIKit

class HomeViewController: ServiceCollectionViewController {
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    override var isEditing: Bool {
        didSet {
            guard let leftBarButtonItem = navigationBar.items?.first?.leftBarButtonItem else {
                return
            }
            
            leftBarButtonItem.title = isEditing ? "Done" : "Edit"
            leftBarButtonItem.style = isEditing ? .done : .plain
        }
    }
    
    var editingIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }
 
    private func setupNavigationBar() {
        navigationBar.delegate = self
        
        let navigationItem = UINavigationItem()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editServicesTapped(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addServiceTapped(_:)))
        
        navigationBar.items = [navigationItem]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Hides the navigationBar's separator
        navigationController?.navigationBar.clipsToBounds = true
    }
    
    // MARK: - BarButtonItem actions
    @objc func addServiceTapped(_ sender: UIBarButtonItem) {
        presentAddServiceViewController()
    }
    
    func presentAddServiceViewController(serviceToEdit: ServiceModel? = nil) {
        let storyboard = UIStoryboard(name: "AddServiceViewController", bundle: nil)
        let addServiceViewController = storyboard.instantiateViewController(withIdentifier: "AddServiceViewController") as! AddServiceViewController
        
        addServiceViewController.serviceDelegate = self
        addServiceViewController.serviceToEdit = serviceToEdit
        
        present(addServiceViewController, animated: true)
    }
    
    @objc func editServicesTapped(_ sender: UIBarButtonItem) {
        isEditing.toggle()
    }
    
    // MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditing {
            editingIndexPath = indexPath
            
            let serviceToEdit = services[indexPath.row]
            presentAddServiceViewController(serviceToEdit: serviceToEdit)
        } else {
            super.collectionView(collectionView, didSelectItemAt: indexPath)
        }
    }
}

// MARK: - ServiceDelegate
extension HomeViewController: ServiceDelegate {
    func onNewServiceCreated(newService: ServiceModel) {
        services.insert(newService, at: 0)
        collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
    }
    
    func onServiceChanged(service: ServiceModel) {
        isEditing = false
        guard let editingIndexPath = editingIndexPath else {
            fatalError("A UICollectionViewCell was edited but its IndexPath is unknown!")
        }
        
        services[editingIndexPath.row] = service
        collectionView.reloadItems(at: [editingIndexPath])
        self.editingIndexPath = nil
    }
}

// MARK - NavigationBarDelegate

extension HomeViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
