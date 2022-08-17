//
//  ViewController.swift
//  TaskCaptureSample
//
//  Created by Akira Matsuda on 2022/08/17.
//

import LocalConsole
import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        LCManager.shared.isVisible = true
    }
}
