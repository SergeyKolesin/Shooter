//
//  Bullet.swift
//  Shooter
//
//  Created by Sergei Kolesin on 1/9/19.
//  Copyright © 2019 Sergei Kolesin. All rights reserved.
//

import ARKit

let bulletNodeName = "bulletNodeName"

class Bullet: SCNNode
{
	init(position: SCNVector3, velocity: SCNVector3)
	{
		super.init()
		geometry = SCNSphere(radius: 0.05)
		name = bulletNodeName
		self.position = position
		geometry?.firstMaterial?.diffuse.contents = UIColor.blue
		geometry?.firstMaterial?.specular.contents = UIColor.purple
		let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: self, options: nil))
		body.isAffectedByGravity = false
		body.velocity = velocity
		body.contactTestBitMask	= body.collisionBitMask
		physicsBody =  body
		DispatchQueue.main.asyncAfter(deadline: .now()+10, execute: { [weak self] in
			if let strongSelf = self
			{
				strongSelf.removeFromParentNode()
			}
		})
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
