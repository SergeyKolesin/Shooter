//
//  SCNVectorExtensions.swift
//  Shooter
//
//  Created by Sergei Kolesin on 12/28/18.
//  Copyright © 2018 Sergei Kolesin. All rights reserved.
//

import ARKit

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3
{
	return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

func -(left: SCNVector3, right: SCNVector3) -> SCNVector3
{
	return left + (-1)*right
}

func *(left: Float, right: SCNVector3) -> SCNVector3
{
	return SCNVector3(left*right.x, left*right.y, left*right.z)
}

extension SCNVector3
{
	func module() -> Float
	{
		return sqrt(x*x + y*y + z*z)
	}
}

