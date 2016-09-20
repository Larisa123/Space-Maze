//
//  HUDScene.swift
//  LabirintTest
//
//  Created by Lara Carli on 8/11/16.
//  Copyright © 2016 Larisa Carli. All rights reserved.
//

import SpriteKit
import SceneKit

enum GameState {
	case loading
	case tapToPlay
	case play
	case levelCleared
	case gameOver
	case cleared
}

enum TutorialState {
	case firstTap
	case secondTap
	case winToComplete
	case wonToComplete
	case completed
}

class Game {
	var level = 1
	var state: GameState = .loading
	var tutorialState: TutorialState = .firstTap

	var sounds: [String:SCNAudioSource] = [:]
	var gameViewController: GameViewController!
	
	var newGameCameraSelfieStickNode: SCNNode?
	var newGameCamera: SCNNode?
	
	init(gameViewController: GameViewController) {
		self.gameViewController = gameViewController
		setupRotatingCamera()
		switchToRotatingCamera()
		setupSounds()
	}
	
	func switchGameStateToTapToPlay() { state = .tapToPlay }
	
	// Camera (in .TapToPlay mode):
	
	func setupRotatingCamera() {
		newGameCamera = gameViewController.levelScene?.rootNode.childNode(withName: "newGameCamera", recursively: true)
		newGameCameraSelfieStickNode = gameViewController.levelScene?.rootNode.childNode(withName: "newGameCameraSelfieStick reference", recursively: true)
		newGameCamera?.constraints = [SCNLookAtConstraint(target: gameViewController.floor)]
	}
	
	func switchToRotatingCamera() {
		gameViewController.scnView.pointOfView = newGameCamera
		gameViewController.hudScene.hideController()
		gameViewController.hudScene.hideReplayButton()
		gameViewController.hudScene.makeHealthBar(visible: false)
		
		gameViewController.hudScene.setLabel(text: "Tap to play!")
	}
	
	// Game:
	
	func newGameDisplay(newLevel: Bool) {
		state = .loading
		
		if newLevel && level < gameViewController.numberOfLevels {
			level += 1
			gameViewController.setHighest(level: level)
			gameViewController.setupSceneLevel(level)
			gameViewController.playerClass.setupThePlayer()
			gameViewController.playerClass.setupPlayersCamera()
			gameViewController.setupNodes() // We have to set them again, because we changed the scene
			setupRotatingCamera() //the camera that is set is not the right one!
			switchToRotatingCamera()
			gameViewController.scnView.overlaySKScene = gameViewController.hudScene
			gameViewController.hudScene.restoreHealthToFull()
		} else if !newLevel && level <= gameViewController.numberOfLevels {
			gameViewController.hudScene.setLabel(text: "Game Over! Tap to play!")
			gameViewController.playerClass.resetPlayersPosition()
		} else if level == gameViewController.numberOfLevels - 1 {
			state = .cleared
		}
		
		//level cleared and restart the game should have diffrent labels
		gameViewController.scnView.pointOfView = newGameCamera
		gameViewController.hudScene.restoreHealthToFull()
		
		state = .tapToPlay // user can tap now, before this touches won't be registered
	}
	
	func startTheGame() {
		state = .loading
		
		gameViewController.scnView.pointOfView = gameViewController.playerClass.camera
		gameViewController.hudScene.hideLabel()
		gameViewController.hudScene.showController()
		if level > 1 { gameViewController.hudScene.showReplayButton() }
		gameViewController.playerClass.resetPlayersPosition()
		gameViewController.hudScene.restoreHealthToFull()
		gameViewController.hudScene.makeHealthBar(visible: true)
		
		state = .play
		if level == 1 { tutorial() }
	}
	
	func gameOver() {
		playSound(node: gameViewController.playerClass.scnNode, name: "GameOver")
		state = .gameOver
		newGameDisplay(newLevel: false)
	}
	
	func collisionWithNode(_ node: SCNNode) {
		let nodeMask = node.physicsBody?.categoryBitMask
		if (node.opacity > 0.2) {
			
			if nodeMask == PhysicsCategory.Pearl {
				let geometry = SCNSphere(radius: 0.1)
				let position = node.presentation.position
				let explosion = gameViewController.pearlExplosionParticleSystem
				createExplosion(explosion!, node: node,  withGeometry: geometry, atPosition: position)
				
				node.removeFromParentNode() // otherwise the player can wait on pearls to reappear and collect points
				gameViewController.hudScene.changeHealth(collidedWithPearl: true)
				playSound(node: gameViewController.playerClass.scnNode, name: "PowerUp")
			} else if nodeMask == PhysicsCategory.Enemy {
				node.opacity = 0.1
				node.runAction(SCNAction.waitForDurationThenRunBlock(5.0) { node in node.opacity = 1.0 })
				gameViewController.deviceVibrate()
				gameViewController.playerClass.animateTransparency()
				playSound(node: gameViewController.playerClass.scnNode, name: "PowerDown")
				gameViewController.hudScene.changeHealth(collidedWithPearl: false)
			}
		}
	}
	func collisionWithWinningPearl(_ pearl: SCNNode) {
		playSound(node: gameViewController.playerClass.scnNode, name: "LevelUp") // the sound effect should play in any case
		pearl.removeFromParentNode()
		
		if level == 1 && tutorialState == .wonToComplete {
			tutorial()
			return
		}
		if level < 4 {
			state = .levelCleared
			gameViewController.hudScene.setLabel(text: "Level \(level) cleared!")
		} else {
			gameViewController.hudScene.setLabel(text: "You have cleared the game!")
			state = .cleared
		}
	}
	
	func createExplosion(_ explosion: SCNParticleSystem, node: SCNNode, withGeometry geometry: SCNGeometry, atPosition position: SCNVector3) {
		let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
		explosion.emitterShape = geometry
		
		gameViewController.levelScene?.addParticleSystem(explosion, transform: translationMatrix)
	}
	
	//Tutorial:
	
	func tutorial() {
		switch tutorialState {
		case .firstTap:
			gameViewController.hudScene.setLabel(text: "Tutorial")
			performScalingActionOn(nodes: gameViewController.hudScene.arrowDictionary["right"]!)
			gameViewController.game.tutorialState = .secondTap
			return
		case .secondTap:
			removeNodesActions(name: "right")
			gameViewController.game.tutorialState = .winToComplete
			performScalingActionOn(nodes: gameViewController.hudScene.arrowDictionary["down"]!)
			return
		case .winToComplete:
			removeNodesActions(name: "down")
			gameViewController.game.tutorialState = .wonToComplete
			return
		case .wonToComplete:
			gameViewController.hudScene.setLabel(text: "Tap To Play Level 1!")
			gameViewController.game.tutorialState = .completed
			gameViewController.game.state = .tapToPlay
			return
		case .completed: return
		}
	}
	
	func performScalingActionOn(nodes: [SKSpriteNode]) {
		let scale: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 1.5 : 1
		
		for node in nodes {
			let scaleUpAndDown = SKAction.sequence([SKAction.scale(to: scale + 0.1 * scale, duration: 1.5), SKAction.scale(to: scale - 0.1 * scale, duration: 1.5)])
			node.run(SKAction.repeatForever(scaleUpAndDown))
		}
	}
	
	func removeNodesActions(name: String) {
		for node in gameViewController.hudScene.arrowDictionary[name]! {
			node.removeAllActions()
			node.size = CGSize(width: gameViewController.hudScene.arrowSize, height: gameViewController.hudScene.arrowSize)
		}
	}
	
	//Sounds:
	
	func loadSound(_ name:String, fileNamed:String) {
		let sound = SCNAudioSource(fileNamed: fileNamed)!
		sound.load()
		sounds[name] = sound
	}
	
	func playSound(node:SCNNode?, name:String) {
		if node != nil {
			if let sound = sounds[name] { node!.runAction(SCNAction.playAudio(sound, waitForCompletion: true)) }
		}
	}
	
	func setupSounds() {
		loadSound("WallCrash", fileNamed: "art.scnassets/Sounds/Explosion.wav")
		loadSound("PowerDown", fileNamed: "art.scnassets/Sounds/PowerDown.mp3")
		loadSound("LevelUp", fileNamed: "art.scnassets/Sounds/LevelUp.mp3")
		loadSound("PowerUp", fileNamed: "art.scnassets/Sounds/PowerUp.mp3")
		loadSound("GameOver", fileNamed: "art.scnassets/Sounds/gameOver.mp3")
	}
}
