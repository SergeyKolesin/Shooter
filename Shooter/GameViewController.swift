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
	
	@IBOutlet weak var helperView: UIView!
	@IBOutlet weak var healthLabel: UILabel!
	@IBOutlet weak var scoreLabel: UILabel!
	@IBOutlet weak var sceneView: ARSCNView!
	var baseTimers = [Timer]()
	var gameTimer: Timer!
	var destroyedBaseCounter = 0
	let userNode = UserNode(position: SCNVector3Zero)
	var position: SCNVector3!
	{
		didSet {
			userNode.position = position
		}
	}
	
	let multipeerService = MultipeerService()
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		multipeerService.delegate = self
		multipeerService.startAdvertisingPeer()
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
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		pauseSession()
	}
	
	func restartSession(_ initialWorldMap: ARWorldMap? = nil)
	{
		pauseSession()
		let configuration = ARWorldTrackingConfiguration()
		configuration.initialWorldMap = initialWorldMap
		let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
		sceneView.session.run(configuration, options: options)
	}
	
	func pauseSession()
	{
		sceneView.session.pause()
		sceneView.scene.rootNode.enumerateChildNodes { (childNode, _) in
			childNode.removeFromParentNode()
			for timer in baseTimers
			{
				timer.invalidate()
			}
		}
	}
	
	func finishGame()
	{
		dismiss(animated: false, completion: nil)
		pauseSession()
		gameTimer.invalidate()
	}
	
	func constructVirtualObjects()
	{
		guard let transform = sceneView.pointOfView?.transform else {return}
		let location = SCNVector3(transform.m41, transform.m42, transform.m43)
		let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
		self.newBase(position: location + (3.0*orientation))
		gameTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(addBase), userInfo: nil, repeats: true)
		sceneView.scene.rootNode.addChildNode(userNode)
	}
	
	@objc func addBase()
	{
		DispatchQueue.main.async {
			self.newBase(position: self.randomBasePosition())
		}
	}
	
	func randomBasePosition() -> SCNVector3
	{
		guard let transform = self.sceneView.pointOfView?.transform else {return SCNVector3()}
		let location = SCNVector3(transform.m41, transform.m42, transform.m43)
		var position = SCNVector3()
		var diff = SCNVector3()
		repeat
		{
			let x = randomNumber(firstNum: -5.0, secondNum: 5.0)
			let y = randomNumber(firstNum: -0.5, secondNum: 0.5)
			let z = randomNumber(firstNum: -5.0, secondNum: 5.0)
			let randomVector = SCNVector3(x, y, z)
			position = location + randomVector
			diff = location - randomVector
		} while diff.module() < 1.0
		return position
	}
	
	func newBase(position: SCNVector3)
	{
		let base = BaseNode(position: position, lookAt: userNode)
		let timer = Timer.scheduledTimer(timeInterval: 4.3, target: base, selector: #selector(base.shoot), userInfo: nil, repeats: true)
		baseTimers.append(timer)
		base.shootTimer = timer
		base.delegate = self
		self.sceneView.scene.rootNode.addChildNode(base)
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
		UIView.animate(withDuration: 0.2, animations: {
			self.helperView.alpha = 1
		}) { (_) in
			self.helperView.alpha = 0
		}
	}
	
	func userDidDestroyed(_ node: UserNode)
	{
		let blockView = UIView(frame: view.frame)
		blockView.backgroundColor = UIColor.clear
		view.addSubview(blockView)
		DispatchQueue.main.asyncAfter(deadline: .now()+3, execute: {
			self.finishGame()
		})
	}
}

extension GameViewController: MultipeerServiceDelegate
{
	func connectedDevicesChanged(manager : MultipeerService, connectedDevices: [String])
	{
		print("QQQ")
//		DispatchQueue.main.async {
//			if connectedDevices.count > 0
//			{
//				self.multipeerLabel.text = connectedDevices.last
//			}
//			else
//			{
//				self.multipeerLabel.text = "No connectedDevices"
//			}
//		}
	}

	func didReceaveData(manager: MultipeerService, data: Data)
	{
		guard let unarchivedMapData = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [ARWorldMap.classForKeyedUnarchiver()], from: data),
			let worldMapData = unarchivedMapData as? ARWorldMap else {
//				self.multipeerLabel.text = "Error: could not unarchive ARWorldMap"
				return
		}

		DispatchQueue.main.async {
			self.restartSession(worldMapData)
//			let configuration = ARWorldTrackingConfiguration()
//
//			configuration.initialWorldMap = worldMapData
//			configuration.planeDetection = .horizontal
//			self.lblMessage.text = "Previous world map loaded"
//			self.sceneView.session.run(configuration)
		}
	}
}
