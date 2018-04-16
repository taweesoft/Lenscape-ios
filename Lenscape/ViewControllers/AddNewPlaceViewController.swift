//
//  AddNewPlaceViewController.swift
//  Lenscape
//
//  Created by TAWEERAT CHAIMAN on 15/4/2561 BE.
//  Copyright © 2561 Lenscape. All rights reserved.
//

import UIKit

class AddNewPlaceViewController: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var placeNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placeNameTextField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Automatically show keyboard
        placeNameTextField.becomeFirstResponder()
    }
    
    @IBAction func back(_ sender: UIBarButtonItem) {
        // Hide keyboard
        placeNameTextField.resignFirstResponder()
        
        dismiss(animated: true)
    }
}

extension AddNewPlaceViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Hide keyboard when touch outside textfields
        self.view.endEditing(true)
    }
}