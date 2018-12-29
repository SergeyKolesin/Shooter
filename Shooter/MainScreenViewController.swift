//
//  MainScreenViewController.swift
//  Shooter
//
//  Created by Sergei Kolesin on 12/28/18.
//  Copyright © 2018 Sergei Kolesin. All rights reserved.
//

import UIKit

class MainScreenViewController: UIViewController
{
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ShowGameVC"
		{
			print("ShowGameVC")
		}
	}
}
