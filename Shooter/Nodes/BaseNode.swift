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
	var shootTimer: Timer!
	let maxHealth = 3
	var currentHealth = 3
	var blockHurt = false
	
	init(position: SCNVector3)
	{
		super.init()
		geometry = SCNSphere(radius: 0.5)
		name = baseNodeName
		self.position = position
		geometry?.firstMaterial?.diffuse.contents = UIColor.green
		geometry?.firstMaterial?.specular.contents = UIColor.purple
		let body = SCNPhysicsBody.static()
		physicsBody = body
		shootTimer = Timer.scheduledTimer(timeInterval: 4.3, target: self, selector: #selector(shoot), userInfo: nil, repeats: true)
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
					self.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
					DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
						self.geometry?.firstMaterial?.diffuse.contents = UIColor.green
						self.blockHurt = false
					})
				}
			}
			else
			{
				guard let remoteEffect = SCNParticleSystem(named: "Media.scnassets/Fire.scnp", inDirectory: nil) else {return}
				remoteEffect.loops = false
				remoteEffect.emitterShape = geometry
				let effectNode = SCNNode()
				effectNode.addParticleSystem(remoteEffect)
				effectNode.position = position
				parent?.addChildNode(effectNode)
				removeFromParentNode()
				delegate?.baseDidDestroyed(self)
			}
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
