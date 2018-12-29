//
//  Helpers.swift
//  Shooter
//
//  Created by Sergei Kolesin on 12/29/18.
//  Copyright © 2018 Sergei Kolesin. All rights reserved.
//

import ARKit

func randomNumber(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat
{
	return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
}
