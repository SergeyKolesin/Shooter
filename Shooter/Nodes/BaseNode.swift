//
//  BaseNode.swift
//  Shooter
//
//  Created by Sergei Kolesin on 12/29/18.
//  Copyright © 2018 Sergei Kolesin. All rights reserved.
//

import ARKit

let baseNodeName = "BaseNodeName"

protocol BaseNodeDelegate: class
{
	func baseDidDestroyed(_ node: BaseNode)
	func getUserPosition() -> SCNVector3
}

class BaseNode: SCNNode
{
	weak var delegate: BaseNodeDelegate?
	var shootTimer: Timer?
	let maxHealth = 3
	var currentHealth = 3
	var blockHurt = false
	
	init(position: SCNVector3, lookAt node: SCNNode)
	{
		super.init()
		geometry = SCNSphere(radius: 0.5)
		name = baseNodeName
		self.position = position
		
		let videoNode = SCNNode(geometry: SCNPlane(width: 2.4, height: 1.8))
		videoNode.geometry?.firstMaterial?.diffuse.contents = videoSKScene()
		videoNode.geometry?.firstMaterial?.isDoubleSided = true
		videoNode.position = SCNVector3(-0.39, 0.30, 0)
		videoNode.eulerAngles.z = .pi
//		videoNode.eulerAngles.y = .pi / 2
		addChildNode(videoNode)
		
		constraints = [SCNLookAtConstraint(target: node)]
		geometry?.firstMaterial?.diffuse.contents = UIColor.clear
//		geometry?.firstMaterial?.specular.contents = UIColor.purple
		let body = SCNPhysicsBody.static()
		physicsBody = body
	}
	
	func videoSKScene() -> SKScene?
	{
		guard let videoURL = Bundle.main.url(forResource: "Halloween", withExtension: "mp4") else { return nil }
		let player = AVPlayer(url: videoURL)
		let playerNode = SKVideoNode(avPlayer: player)
		playerNode.anchorPoint = CGPoint(x: 0.0, y: 0.0)
		let spriteKitScene = SKScene(size: CGSize(width: 1920,
												  height: 1080))
		spriteKitScene.backgroundColor = UIColor.clear

		let effectNode = SKEffectNode()
		effectNode.addChild(playerNode)
		effectNode.filter = colorCubeFilterForChromaKey(hueAngle: 110)

		spriteKitScene.addChild(effectNode)
		player.play()

		NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
											   object: player.currentItem, queue: nil)
		{ _ in
			player.seek(to: CMTime.zero)
			player.play()
		}
		
		return spriteKitScene
	}
	
	@objc func shoot()
	{
		guard let delegate = delegate else {return}
		let direction = delegate.getUserPosition() - position
		let module = direction.module()
		let velocity = 2 * (1/module) * direction
		
		let bulletPosition = position + 0.7 * (1/module) * direction
		let bullet = Bullet(position: bulletPosition, velocity: velocity)
		parent?.addChildNode(bullet)
	}
	
	func getHurt()
	{
		if !blockHurt
		{
			currentHealth -= 1
			blockHurt = true
			
			if currentHealth > 0
			{
				DispatchQueue.main.async {
//					self.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
					DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
//						self.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
						self.blockHurt = false
					})
				}
			}
			else
			{
				DispatchQueue.main.async {
					guard let remoteEffect = SCNParticleSystem(named: "Media.scnassets/Fire.scnp", inDirectory: nil) else {return}
					remoteEffect.loops = false
					remoteEffect.emitterShape = self.geometry
					let effectNode = SCNNode()
					effectNode.addParticleSystem(remoteEffect)
					effectNode.position = self.position
					self.parent?.addChildNode(effectNode)
					self.removeFromParentNode()
					self.delegate?.baseDidDestroyed(self)
					self.shootTimer?.invalidate()
				}
			}
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
