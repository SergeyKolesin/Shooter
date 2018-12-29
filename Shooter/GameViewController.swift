//
//  GameViewController.swift
//  Shooter
//
//  Created by Sergei Kolesin on 12/28/18.
//  Copyright © 2018 Sergei Kolesin. All rights reserved.
//

import ARKit
import AudioToolbox

class GameViewController: UIViewController
{
	
	@IBOutlet weak var scoreLabel: UILabel!
	@IBOutlet weak var sceneView: ARSCNView!
	var gameTimer: Timer!
	var destroyedBaseCounter = 0
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
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
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
	}
	
	@objc func addBase()
	{
		DispatchQueue.main.async {
			guard let transform = self.sceneView.pointOfView?.transform else {return}
			let location = SCNVector3(transform.m41, transform.m42, transform.m43)
			let x = randomNumber(firstNum: -5.0, secondNum: 5.0)
			let y = randomNumber(firstNum: -5.0, secondNum: 5.0)
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
		
		let bullet = SCNNode(geometry: SCNSphere(radius: 0.05))
		bullet.position = location + (0.1*orientation)
		bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
		bullet.geometry?.firstMaterial?.specular.contents = UIColor.purple
		let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: bullet, options: nil))
		body.isAffectedByGravity = false
		body.velocity = 4.0*orientation
//		body.categoryBitMask = BitMaskCategory.bullet.rawValue
		body.contactTestBitMask	= body.collisionBitMask
		bullet.physicsBody =  body
		
		sceneView.scene.rootNode.addChildNode(bullet)
		
		DispatchQueue.main.asyncAfter(deadline: .now()+10, execute: { [weak bullet] in
			if let strongBullet = bullet
			{
				strongBullet.removeFromParentNode()
			}
		})
	}
	
}

extension GameViewController: ARSCNViewDelegate
{
	
}

extension GameViewController: ARSessionDelegate
{
	
}

extension GameViewController: SCNPhysicsContactDelegate
{
	func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
		var node = SCNNode()
		if contact.nodeA.name == baseNodeName
		{
			node = contact.nodeA
		}
		else if contact.nodeB.name == baseNodeName
		{
			node = contact.nodeB
		}
		guard let baseNode = node as? BaseNode else {return}
		baseNode.getHurt()
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
			if self.destroyedBaseCounter > 2
			{
				self.dismiss(animated: false, completion: nil)
			}
		}
	}
}
