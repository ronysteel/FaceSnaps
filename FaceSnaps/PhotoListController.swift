//
//  PhotoListController.swift
//  FaceSnaps
//
//  Created by Patrick Montalto on 10/1/16.
//  Copyright © 2016 Patrick Montalto. All rights reserved.
//

import UIKit
import CoreData

class PhotoListController: UIViewController {
    
    // Lazy stored property with an immediately executing closure
    // Let's us put the initialization and customization all in one place, instead of splitting it up
    // between the class body and viewDidLoad
    lazy var cameraButton: UIButton = {
        let button = UIButton(type: UIButtonType.system)
        button.setTitle("Camera", for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 254/255.0, green: 123/255.0, blue: 135/255.0, alpha: 1.0)
        
        button.addTarget(self, action: #selector(PhotoListController.presentImagePickerController), for: .touchUpInside)
        
        return button
    }()
    
    lazy var mediaPickerManager: MediaPickerManager = {
        let manager = MediaPickerManager(presentingViewController: self)
        manager.delegate = self
        return manager
    }()
    
    lazy var dataSource: UICollectionViewDataSource = {
        return PhotoDataSource(fetchRequest: Photo.allPhotosRequest, collectionView: self.collectionView)
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        
        let screenWidth = UIScreen.main.bounds.size.width
        let paddingDistance: CGFloat = 16.0
        let itemSize = (screenWidth - paddingDistance)/2.0
        
        collectionViewLayout.itemSize = CGSize(width: itemSize, height: itemSize)
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .white
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.reuseIdentifier)
        
        return collectionView
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        
        collectionView.dataSource = dataSource
        // Remove white space between Navbar and Collectionview
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    // MARK: - Layout
    
    override func viewWillLayoutSubviews() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(cameraButton)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cameraButton.leftAnchor.constraint(equalTo: view.leftAnchor),
            cameraButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cameraButton.rightAnchor.constraint(equalTo: view.rightAnchor),
            cameraButton.heightAnchor.constraint(equalToConstant: 56.0)
        ])
    }
    
    // MARK: - Image Picker Controller

    @objc private func presentImagePickerController() {
        mediaPickerManager.presentImagePickerController(animated: true)
    }


}

// MARK: - MediaPickerManagerDelegate
extension PhotoListController: MediaPickerManagerDelegate {
    func mediaPickerManager(manager: MediaPickerManager, didFinishPickingImage image: UIImage) {
        // We now got an image available in our PhotoListController
        
        let eaglContext = EAGLContext(api: .openGLES2)!
        let ciContext = CIContext(eaglContext: eaglContext)
        
        let photoFilterController = PhotoFilterController(image: image, context: ciContext, eaglContext: eaglContext)
        let navigationController = UINavigationController(rootViewController: photoFilterController)
        
        mediaPickerManager.dismissImagePickerController(animated: true) { 
            self.present(navigationController, animated: true, completion: nil)
        }
        
    }
}

// MARK: - Navigation
extension PhotoListController {
    
    func setupNavigationBar() {
        // TODO: Implement location sorting
        let sortTagsButton = UIBarButtonItem(title: "Tags", style: .plain, target: self, action: #selector(PhotoListController.presentSortController))
        navigationItem.setRightBarButtonItems([sortTagsButton], animated: true)
    }
    
    @objc private func presentSortController() {
        let tagDataSource = SortableDataSource<Tag>(fetchRequest: Tag.allTagsRequest, managedObjectContext: CoreDataController.sharedInstance.managedObjectContext)
        
        let sortItemSelector = SortItemSelector(sortItems: tagDataSource.results)
        
        let sortController = PhotoSortListController(dataSource: tagDataSource, sortItemSelector: sortItemSelector)
        sortController.onSortSelection = { checkedItems in
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Photo.entityName)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
            
            // Check that checkedItems isn't empty, otherwise there's no need for a predicate
            if !checkedItems.isEmpty {
                var predicates = [NSPredicate]()
                for tag in checkedItems {
                    let predicate = NSPredicate(format: "%K CONTAINS %@", "tags.title", tag.title)
                    predicates.append(predicate)
                }

                let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                
                fetchRequest.predicate = compoundPredicate
            }
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        }
        
        let navigationController = UINavigationController(rootViewController: sortController)
        
        present(navigationController, animated: true, completion: nil)
        
    }
}






















