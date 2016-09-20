//
//  GameViewController.swift
//  LabirintTest
//
//  Created by Lara Carli on 7/28/16.
//  Copyright (c) 2016 Larisa Carli. All rights reserved.
//


	
import UIKit
import SceneKit
import Darwin
import SpriteKit
import AVFoundation
import AudioToolbox

struct PhysicsCategory {
	static let None: Int = 0
	static let Player: Int = 1
	static let Wall: Int = 2
	static let Pearl: Int = 4
	static let Enemy: Int = 8
	static let WinningPearl: Int = 16
	static let CornerNode: Int = 32
	static let Floor: Int = 64
}

var backgroundMusicPlayer:AVAudioPlayer = AVAudioPlayer()


class GameViewController: UIViewController {
	
	var scnView: SCNView!
	var deviceSize: CGSize!
	var levelScene: SCNScene?
	var floor: SCNNode?
	
	var enemyParticleSystem: SCNParticleSystem!
	var pearlExplosionParticleSystem: SCNParticleSystem!
	var smallPearlParticleSystem: SCNParticleSystem!
	var pearlParticleSystem: SCNParticleSystem!
	//var starsParticleSystem: SCNParticleSystem!
	
	var playerClass: Player!
	var winningPearl: SCNNode?
	var firstCornerNode: SCNNode?
	
	var collisionCounter = 1 // this ensures contact with objects is only detected once
	
	//HUD
	var hudScene: hudSKSScene!
	
	var game: Game!
	var currentLevel = 1
	let numberOfLevels = 4
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		deviceSize = UIScreen.main.bounds.size
		
		setupView()
		playBackgroundMusic()
		//level = highestLevel()
		setupSceneLevel(1) //which level to load
		setupHUD()
		setupPlayerClass() // on PlayerClass initialization, player and the camera that follows the player is initialized
		setupParticleSystems()
		setupNodes() // we setup properties to nodes set in scenes and add them particle systems
		
		setupGameClass() //on GameClass initialization, cameras and sounds are automatically initializied
		game.switchGameStateToTapToPlay()
	}
	
	func setupView() {
		scnView = self.view as! SCNView
		scnView.antialiasingMode = .multisampling2X // smooths the edges
		scnView.delegate = self
	}
	
	func playBackgroundMusic() {
		let bgMusicURL:URL = Bundle.main.url(forResource: "art.scnassets/Sounds/Puzzle-Game_Looping", withExtension: "mp3")!
		do { backgroundMusicPlayer = try AVAudioPlayer(contentsOf: bgMusicURL) } catch _ {return }
		backgroundMusicPlayer.numberOfLoops = -1 //loops the sound
		if backgroundMusicPlayer.prepareToPlay() {
			backgroundMusicPlayer.volume = 0.4
			backgroundMusicPlayer.play()
		}
	}
	
	func setupSceneLevel(_ level: Int) {
		if level <= numberOfLevels {
			levelScene = SCNScene(named: "Level\(level).scn")
			if levelScene != nil { scnView.scene = levelScene! }
			currentLevel = level
			
			levelScene?.physicsWorld.contactDelegate = self
		}
	}
	
	func setupHUD() {
		hudScene = hudSKSScene(gameViewController: self)
		scnView.overlaySKScene = hudScene
	}
	
	func setupPlayerClass() { playerClass = Player(viewController: self) }
	
	func setupParticleSystems() {
		enemyParticleSystem = SCNParticleSystem(named: "enemyParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		pearlExplosionParticleSystem = SCNParticleSystem(named: "pearlExplodeParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		pearlParticleSystem = SCNParticleSystem(named: "pearlParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		smallPearlParticleSystem = SCNParticleSystem(named: "smallPearlParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
		//starsParticleSystem = SCNParticleSystem(named: "starsParticleSystem.scnp", inDirectory: "art.scnassets/Particles/starsParticleSystem.scnp")
	}
	
	func setupNodes() {
		levelScene?.rootNode.enumerateChildNodes { node, stop in
			if self.currentLevel == 1  {
				if node.name == "CornerNode" {
					node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
					node.physicsBody?.categoryBitMask = PhysicsCategory.CornerNode
					node.physicsBody?.collisionBitMask = PhysicsCategory.None
					node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
				}
			}
			
			if node.name == "pearl reference" {
				node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
				node.physicsBody?.categoryBitMask = PhysicsCategory.Pearl
				node.physicsBody?.collisionBitMask = PhysicsCategory.None
				node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
				node.addParticleSystem(self.smallPearlParticleSystem)
			}
			if node.name == "enemy reference" {
				node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
				node.physicsBody?.categoryBitMask = PhysicsCategory.Enemy
				node.physicsBody?.collisionBitMask = PhysicsCategory.None
				node.physicsBody?.contactTestBitMask = PhysicsCategory.Player
				node.addParticleSystem(self.enemyParticleSystem)
			}
		}
		
		floor = levelScene?.rootNode.childNode(withName: "floorObject reference", recursively: true)
		floor?.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
		floor?.physicsBody?.categoryBitMask = PhysicsCategory.Floor
		floor?.physicsBody?.collisionBitMask = PhysicsCategory.Player
		floor?.physicsBody?.contactTestBitMask = PhysicsCategory.None
		
		winningPearl = levelScene?.rootNode.childNode(withName: "winningPearl reference", recursively: true)
		winningPearl?.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
		winningPearl?.physicsBody?.categoryBitMask = PhysicsCategory.WinningPearl
		winningPearl?.physicsBody?.collisionBitMask = PhysicsCategory.None
		winningPearl?.physicsBody?.contactTestBitMask = PhysicsCategory.Player
		winningPearl?.addParticleSystem(pearlParticleSystem)
	}
	
	func setupGameClass() {
		game = Game(gameViewController: self)
		game.level = currentLevel
	}
	func highestLevel() -> Int {
		let result = UserDefaults.standard.integer(forKey: "highestLevel") // the default value is 0
		return result == 0 ? 1: result
	}
	func setHighest(level: Int) {
		UserDefaults.standard.set(level, forKey: "highestLevel")
		UserDefaults.standard.synchronize()
	}
	
	func deviceVibrate() {
		// why does it not vibrate?
		AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
	}
	
	override func didReceiveMemoryWarning() { print("memory warning") }
	override var prefersStatusBarHidden: Bool { get { return true } }
}


extension GameViewController: SCNSceneRendererDelegate {
	
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		if game.state == .tapToPlay { game.newGameCameraSelfieStickNode?.eulerAngles.y += 0.002 }
		else if game.state == .play {
			playerClass.updateCameraThatFollowsThePlayer()
			
			if (playerClass.scnNode?.presentation.position.y)! < -8.0 {
				game.gameOver()
			}
		}
	}
}

extension GameViewController: SCNPhysicsContactDelegate {

	func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
		if game.state == .play {
			let otherNode: SCNNode!			
			
			if contact.nodeA.categoryBitMask == PhysicsCategory.Player { otherNode = contact.nodeB }
			else { otherNode = contact.nodeA }
			
			let nodeMask = otherNode.physicsBody?.categoryBitMask
			
			if currentLevel == 1 && nodeMask == PhysicsCategory.CornerNode {
				if collisionCounter == 1 {
					otherNode.removeFromParentNode()
					game.tutorial()
				}
			}
			else if nodeMask == PhysicsCategory.Wall {
				if collisionCounter == 1 { game.playSound(node: otherNode, name: "WallCrash") }
			} else if nodeMask == PhysicsCategory.Pearl || nodeMask == PhysicsCategory.Enemy {
				if collisionCounter == 1 { game.collisionWithNode(otherNode) }
			} else if nodeMask == PhysicsCategory.WinningPearl {
				if collisionCounter == 1 { game.collisionWithWinningPearl(otherNode) }
			} else {return }
			collisionCounter += 1
		playerClass.scnNode?.runAction(SCNAction.waitForDurationThenRunBlock(0.2, block: {node in self.collisionCounter = 1 }))
		}
	}
}
