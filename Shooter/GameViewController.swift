//
//  GameViewController.swift
//  Shooter
//
//  Created by Sergei Kolesin on 12/28/18.
//  Copyright © 2018 Sergei Kolesin. All rights reserved.
//

import ARKit
import AudioToolbox

let maxHealth = 10

class GameViewController: UIViewController
{
	
	@IBOutlet weak var healthLabel: UILabel!
	@IBOutlet weak var scoreLabel: UILabel!
	@IBOutlet weak var sceneView: ARSCNView!
	var gameTimer: Timer!
	var destroyedBaseCounter = 0
	let userNode = UserNode(position: SCNVector3Zero)
	var position: SCNVector3!
	{
		didSet {
			userNode.position = position
		}
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		userNode.delegate = self
		healthLabel.text = String(userNode.maxHealth)
		sceneView.autoenablesDefaultLighting = true
		sceneView.delegate = self
		sceneView.session.delegate = self
		sceneView.scene.physicsWorld.contactDelegate = self
		addGestures()
	}
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		restartSession()
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			self.constructVirtualObjects()
		}
	}
	
	func restartSession()
	{
		pauseSession()
		let configuration = ARWorldTrackingConfiguration()
		let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
		sceneView.session.run(configuration, options: options)
	}
	
	func pauseSession()
	{
		sceneView.session.pause()
		sceneView.scene.rootNode.enumerateChildNodes { (childNode, _) in
			childNode.removeFromParentNode()
		}
	}
	
	func constructVirtualObjects()
	{
		guard let transform = sceneView.pointOfView?.transform else {return}
		let location = SCNVector3(transform.m41, transform.m42, transform.m43)
		let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
		let base = BaseNode(position: location + (3.0*orientation))
		base.delegate = self
		sceneView.scene.rootNode.addChildNode(base)
		gameTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(addBase), userInfo: nil, repeats: true)
		sceneView.scene.rootNode.addChildNode(userNode)
	}
	
	@objc func addBase()
	{
		DispatchQueue.main.async {
			guard let transform = self.sceneView.pointOfView?.transform else {return}
			let location = SCNVector3(transform.m41, transform.m42, transform.m43)
			let x = randomNumber(firstNum: -5.0, secondNum: 5.0)
			let y = randomNumber(firstNum: -0.5, secondNum: 0.5)
			let z = randomNumber(firstNum: -5.0, secondNum: 5.0)
			let randomVector = SCNVector3(x, y, z)
			let position = location + randomVector
			let base = BaseNode(position: position)
			base.delegate = self
			self.sceneView.scene.rootNode.addChildNode(base)
		}
	}
	
	// MARK: Gestures
	
	func addGestures()
	{
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
		sceneView.addGestureRecognizer(tapGesture)
	}
	
	@objc func handleTap(sender: UITapGestureRecognizer)
	{
		shoot()
	}
	
	func shoot()
	{
		guard let transform = sceneView.pointOfView?.transform else {return}
		let location = SCNVector3(transform.m41, transform.m42, transform.m43)
		let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
		
		let bullet = Bullet(position: location + (0.4*orientation), velocity: 4.0*orientation)
		sceneView.scene.rootNode.addChildNode(bullet)
	}
	
}

extension GameViewController: ARSCNViewDelegate
{
	
}

extension GameViewController: ARSessionDelegate
{
	func session(_ session: ARSession, didUpdate frame: ARFrame)
	{
		guard let transform = sceneView.pointOfView?.transform else {return}
		position = SCNVector3(transform.m41, transform.m42, transform.m43)
	}
}

extension GameViewController: SCNPhysicsContactDelegate
{
	func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact)
	{
		var node = SCNNode()
		if contact.nodeA.name == baseNodeName || contact.nodeA.name == userNodeName
		{
			node = contact.nodeA
		}
		else if contact.nodeB.name == baseNodeName || contact.nodeB.name == userNodeName
		{
			node = contact.nodeB
		}
		
		if let baseNode = node as? BaseNode
		{
			baseNode.getHurt()
		}
		if let userNode = node as? UserNode
		{
			userNode.getHurt()
		}
	}
}

extension GameViewController: BaseNodeDelegate
{
	func baseDidDestroyed(_ node: BaseNode)
	{
		DispatchQueue.main.async {
			self.destroyedBaseCounter += 1
			self.scoreLabel.text = String(self.destroyedBaseCounter)
			AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
		}
	}
	
	func getUserPosition() -> SCNVector3
	{
		return position
	}
}

extension GameViewController: UserNodeDelegate
{
	func gotHurt(_ node: UserNode)
	{
		healthLabel.text = String(node.currentHealth)
		AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
	}
	
	func userDidDestroyed(_ node: UserNode)
	{
		let blockView = UIView(frame: view.frame)
		blockView.backgroundColor = UIColor.clear
		view.addSubview(blockView)
		DispatchQueue.main.asyncAfter(deadline: .now()+3, execute: {
			self.dismiss(animated: false, completion: nil)
		})
	}
}
