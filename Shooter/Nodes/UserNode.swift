//
//  UserNode.swift
//  Shooter
//
//  Created by Sergei Kolesin on 1/9/19.
//  Copyright © 2019 Sergei Kolesin. All rights reserved.
//

import ARKit

let userNodeName = "userNodeName"

protocol UserNodeDelegate: class
{
	func userDidDestroyed(_ node: UserNode)
	func gotHurt(_ node: UserNode)
}

class UserNode: SCNNode
{
	var blockHurt = false
	let maxHealth = 7
	var currentHealth = 7
	weak var delegate: UserNodeDelegate?
	
	init(position: SCNVector3)
	{
		super.init()
		geometry = SCNSphere(radius: 0.2)
		name = userNodeName
		self.position = position
		let body = SCNPhysicsBody.static()
		physicsBody = body
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
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
					self.delegate?.gotHurt(self)
					DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
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
					self.delegate?.gotHurt(self)
					self.delegate?.userDidDestroyed(self)
				}
			}
		}
	}
}
