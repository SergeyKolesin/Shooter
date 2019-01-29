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

func colorCubeFilterForChromaKey(hueAngle: Float) -> CIFilter {
	
	let hueRange: Float = 20 // degrees size pie shape that we want to replace
	let minHueAngle: Float = (hueAngle - hueRange/2.0) / 360
	let maxHueAngle: Float = (hueAngle + hueRange/2.0) / 360
	
	let size = 64
	var cubeData = [Float](repeating: 0, count: size * size * size * 4)
	var rgb: [Float] = [0, 0, 0]
	var hsv: (h : Float, s : Float, v : Float)
	var offset = 0
	
	for z in 0 ..< size {
		rgb[2] = Float(z) / Float(size) // blue value
		for y in 0 ..< size {
			rgb[1] = Float(y) / Float(size) // green value
			for x in 0 ..< size {
				
				rgb[0] = Float(x) / Float(size) // red value
				hsv = RGBtoHSV(r: rgb[0], g: rgb[1], b: rgb[2])
				// TODO: Check if hsv.s > 0.5 is really nesseccary
				let alpha: Float = (hsv.h > minHueAngle && hsv.h < maxHueAngle) ? 0 : 1.0
				//					let alpha: Float = (hsv.h > minHueAngle && hsv.h < maxHueAngle && hsv.s > 0.5) ? 0 : 1.0
				
				cubeData[offset] = rgb[0] * alpha
				cubeData[offset + 1] = rgb[1] * alpha
				cubeData[offset + 2] = rgb[2] * alpha
				cubeData[offset + 3] = alpha
				offset += 4
			}
		}
	}
	let b = cubeData.withUnsafeBufferPointer { Data(buffer: $0) }
	let data = b as NSData
	
	let colorCube = CIFilter(name: "CIColorCube", parameters: [
		"inputCubeDimension": size,
		"inputCubeData": data
		])
	return colorCube!
}

func RGBtoHSV(r : Float, g : Float, b : Float) -> (h : Float, s : Float, v : Float) {
	var h : CGFloat = 0
	var s : CGFloat = 0
	var v : CGFloat = 0
	let col = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
	col.getHue(&h, saturation: &s, brightness: &v, alpha: nil)
	return (Float(h), Float(s), Float(v))
}
