//
//  hudSKScene.swift
//  LabirintTest
//
//  Created by Lara Carli on 8/11/16.
//  Copyright © 2016 Larisa Carli. All rights reserved.
//

import SpriteKit
import SceneKit

class hudSKSScene: SKScene {
	var controller: SKSpriteNode!
	var controllerRadius: CGFloat!
	var labelNode: SKLabelNode!
	var gameViewController: GameViewController!
	
	var arrowDictionary: [String: [SKSpriteNode]] = [String: [SKSpriteNode]]()
	var downPressedArror: SKSpriteNode?
	var replayButton: SKSpriteNode!
	var arrowSize: CGFloat!
	
	//Hearts:
	var lives = 9
	var hearts: [SKSpriteNode] = []
	
	
	init(gameViewController: GameViewController) {
		super.init(size: CGSize(width: 600, height: 300))
		self.gameViewController = gameViewController
		
		//setup the overlay scene
		self.anchorPoint = CGPoint.zero
		//automatically resize to fill the viewport
		self.scaleMode = .resizeFill
		
		//make UI larger on iPads:
		
		let scale: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 1.5 : 1
		
		setupArrows(scale: scale)
		setupHealthBar(scale: scale)
		setupLabelNode(scale: scale)
		setupReplayButton(scale: scale)
	}
	
	// Controller:
	
	func setupArrows(scale: CGFloat) {
		let controllerScene = SKScene(fileNamed: "controllerScene.sks")
		
		let arrowsNode = controllerScene?.childNode(withName: "arrows")
		let arrowsPressedNode = controllerScene?.childNode(withName: "arrowsPressed")
		
		let arrowUp = arrowsNode?.childNode(withName: "up") as! SKSpriteNode
		let arrowDown = arrowsNode?.childNode(withName: "down") as! SKSpriteNode
		let arrowLeft = arrowsNode?.childNode(withName: "left") as! SKSpriteNode
		let arrowRight = arrowsNode?.childNode(withName: "right") as! SKSpriteNode
		
		let arrowUpPressed = arrowsPressedNode?.childNode(withName: "upPressed") as! SKSpriteNode
		let arrowDownPressed = arrowsPressedNode?.childNode(withName: "downPressed") as! SKSpriteNode
		let arrowLeftPressed = arrowsPressedNode?.childNode(withName: "leftPressed") as! SKSpriteNode
		let arrowRightPressed = arrowsPressedNode?.childNode(withName: "rightPressed") as! SKSpriteNode
		
		arrowDictionary["up"] = [arrowUp, arrowUpPressed]
		arrowDictionary["down"] = [arrowDown, arrowDownPressed]
		arrowDictionary["left"] = [arrowLeft, arrowLeftPressed]
		arrowDictionary["right"] = [arrowRight, arrowRightPressed]
		
		let arrowsCenter = CGPoint(x: 130 * scale, y: 130 * scale)
		arrowsNode?.position = arrowsCenter
		arrowsNode?.setScale(scale)
		arrowsPressedNode?.setScale(scale)
		arrowsPressedNode?.position = arrowsCenter
		
		for arrowArray in arrowDictionary.values {
			for arrow in arrowArray {
				arrow.isHidden = true
				arrow.setScale(scale)
				arrow.move(toParent: self)
			}
		}
		arrowSize = arrowDictionary["up"]?[0].size.width
	}
	
	func hideController() {
		for arrowArray in arrowDictionary.values {
			for arrow in arrowArray { arrow.isHidden = true }
		}
	}
	func showController() {
		for arrowArray in arrowDictionary.values {
			for arrow in arrowArray { arrow.isHidden = false }
		}
	}
	
	//Replay:
	
	func setupReplayButton(scale: CGFloat) {
		replayButton = SKSpriteNode(imageNamed: "art.scnassets/replay.png")
		replayButton.size = CGSize(width: 55 * scale, height: 55 * scale)
		replayButton.anchorPoint = CGPoint(x: 1, y: 1)
		
		replayButton.position = CGPoint(x: gameViewController.deviceSize.width * 0.98, y: gameViewController.deviceSize.height * 0.98)
		replayButton.isHidden = true
		replayButton.name = "replay"
		addChild(replayButton)
	}
	
	func hideReplayButton() { replayButton.isHidden = true }
	func showReplayButton() { replayButton.isHidden = false }
	
	//Health bar:
	
	func setupHealthBar(scale: CGFloat) {
		let heartSize =  CGSize(width: 30 * scale, height: 30 * scale)
		
		for i in 0..<3 {
			let heart: SKSpriteNode? = SKSpriteNode(imageNamed: "art.scnassets/heart.png")
			heart?.size = heartSize
			heart?.position = CGPoint(x: heartSize.width + CGFloat(i) * heartSize.width * 1.1, y: gameViewController.deviceSize.height * 0.95)
			heart?.isHidden = true
			if heart != nil {
				hearts.append(heart!)
				addChild(heart!)
			}
		}
	}
	
	func restoreHealthToFull() {
		for heart in hearts {
			heart.alpha = 1.0
			heart.isHidden = true
		}
		lives = 9
	}
	
	func makeHealthBar(visible: Bool) {
		for heart in hearts { heart.isHidden = visible ? false: true }
	}
	
	func changeHealth(collidedWithPearl: Bool) {
		if collidedWithPearl { healthUp() }
		else { healthDown() }
	}
	
	func healthUp() {
		if lives < 9 {
			let heart = lives >= 6 ? hearts[2] : (lives >= 3 ? hearts[1] : hearts[0])
			if heart.alpha < 0.7 {
				heart.alpha += 0.35
			}
			else { heart.isHidden = false }
			lives += 1
		}
	}
	
	func healthDown() {
		for _ in 0..<3 {
			let heart = lives > 6 ? hearts[2] : (lives > 3 ? hearts[1] : hearts[0])
			if heart.alpha > 0.2 {
				heart.alpha -= 0.35
			}
			else { heart.isHidden = true }
			lives -= 1
			if lives == 0 { gameViewController.game.gameOver() }
		}
	}
	
	//Label:
	
	func setupLabelNode(scale: CGFloat) {
		labelNode = SKLabelNode(fontNamed: "GillSans-UltraBold")
		labelNode.fontColor = UIColor.white
		labelNode.fontSize = (scale == 1) ? 36: 54
		labelNode.position = CGPoint(x: gameViewController.deviceSize.width / 2, y: gameViewController.deviceSize.height * 0.87)
		labelNode.zPosition = 5.0
		labelNode.isHidden = true
		addChild(labelNode)
	}
	
	func setLabel(text: String) {
		labelNode.text = text
		showLabel()
		if text == "Tutorial" { return }
		let scaleUpAndDown = SKAction.sequence([SKAction.scale(to: 1.1, duration: 1.5), SKAction.scale(to: 0.9, duration: 1.5)])
		labelNode.run(SKAction.repeatForever(scaleUpAndDown))
	}
	func hideLabel() {
		labelNode.isHidden = true
		labelNode.removeAllActions()
	}
	func showLabel() { labelNode.isHidden = false }
	
	//Touches:
	
	func isTouchOnTheOutsideEdge(touchLocation: CGPoint) -> Bool {
		return abs(touchLocation.x) > controllerRadius/2 || abs(touchLocation.y) > controllerRadius/2
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		switch gameViewController.game.state {
			case .loading: return 
			case .tapToPlay:
				if gameViewController.game.level == 1 && gameViewController.game.tutorialState == .completed {
					gameViewController.game.newGameDisplay(newLevel: true)
				}
				gameViewController.game.startTheGame()
			case .play:
				for touch in touches {
					if let spriteAtPoint = atPoint(touch.location(in: self)) as? SKSpriteNode {
						
						downPressedArror = spriteAtPoint
						downPressedArror?.alpha = 0.1
						
						gameViewController.playerClass.moving = true

						let spriteName: String = spriteAtPoint.name!
						
						switch spriteName {
						case "up": gameViewController.playerClass.direction = .forward
						case "down": gameViewController.playerClass.direction = .backward
						case "left": gameViewController.playerClass.direction = .left
						case "right": gameViewController.playerClass.direction = .right
						case "replay":
							gameViewController.playerClass.moving = false
							if gameViewController.currentLevel > 1 { gameViewController.game.startTheGame() }
						default:
							gameViewController.playerClass.moving = false
							return
						}
						gameViewController.playerClass.playerRoll()
					}
				}
			case .levelCleared:
				gameViewController.hudScene.hideLabel()
				gameViewController.game.newGameDisplay(newLevel: true)
			case .gameOver: gameViewController.game.newGameDisplay(newLevel: false)
			case .cleared: //start from beginning:
				gameViewController.game.level = 1
				gameViewController.game.newGameDisplay(newLevel: true)
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if gameViewController.game.state == GameState.play {
			gameViewController.playerClass.stopThePlayer()
			downPressedArror?.alpha = 0.7
			downPressedArror = nil
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
