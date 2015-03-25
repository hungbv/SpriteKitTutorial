//
//  GameScene.swift
//  SpriteKitTutorial
//
//  Created by Bui Van Hung on 3/24/15.
//  Copyright (c) 2015 com.framgia. All rights reserved.
//

import SpriteKit
import AVFoundation

var backgroundMusicPlayer: AVAudioPlayer!

func playBackgroundMusic(filename: String) {
    let url = NSBundle.mainBundle().URLForResource(
        filename, withExtension: nil)
    if (url == nil) {
        println("Could not find file: \(filename)")
        return
    }
    
    var error: NSError? = nil
    backgroundMusicPlayer =
        AVAudioPlayer(contentsOfURL: url, error: &error)
    if backgroundMusicPlayer == nil {
        println("Could not create audio player: \(error!)")
        return
    }
    
    backgroundMusicPlayer.numberOfLoops = -1
    backgroundMusicPlayer.prepareToPlay()
    backgroundMusicPlayer.play()
}

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Monster   : UInt32 = 0b1
    static let Projectile: UInt32 = 0b10
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // Tạo biến constant property
    let player = SKSpriteNode(imageNamed: "player")
    var monstersDestroyed = 0
    
    override func didMoveToView(view: SKView) {

        playBackgroundMusic("background-music-aac.caf")

        // Set background cho GameScene
        backgroundColor = SKColor.whiteColor()
        // Set position của sprite node player
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        // add sprite node player vào GameScene
        addChild(player)

        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self

        runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(addMonster),
                SKAction.waitForDuration(1.0)
            ])
        ))
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
        // Khởi tạo sprite node monster
        let monster = SKSpriteNode(imageNamed: "monster")
        
        // Vị trí theo chiều Y của monster
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        
        // Vị trí của monster
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        // Thêm monster vào GameScene
        addChild(monster)
        
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size) // 1
        monster.physicsBody?.dynamic = true // 2
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster // 3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None // 5

        // Tốc độ của monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // Tạo các action
        let actionMove = SKAction.moveTo(CGPoint(x: -monster.size.width/2, y: actualY), duration: NSTimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        // Gán action cho monster
//        monster.runAction(SKAction.sequence([actionMove, actionMoveDone]))

        let loseAction = SKAction.runBlock() {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        monster.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        // 1 - Xác định vị trí người dùng chạm vào màn hình
        let touch = touches.anyObject() as UITouch
        let touchLocation = touch.locationInNode(self)
        
        // 2 - Tạo và xác định vị trí của đối tượng phi tiêu
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.dynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        // 3 - Xác định khoảng cách các chiều X, Y của vị trí người dùng chạm và vị trí phi tiêu
        let offset = touchLocation - projectile.position
        
        // 4 - Không cho phi tiêu bay ngược ra sau player
        if (offset.x < 0) { return }
        
        // 5 - thêm đối tượng phi tiêu vào GameScene
        addChild(projectile)
        
        // 6 - Xác định hướng bay của phi tiêu
        let direction = offset.normalized()
        
        // 7 - x1000 Để đảm bảo phi tiêu bay hết màn hình
        let shootAmount = direction * 1000
        
        // 8 - Tạo điểm đến cho phi tiêu
        let realDest = shootAmount + projectile.position
        
        // 9 - tạo và gán các action cho phi tiêu
        let actionMove = SKAction.moveTo(realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
        projectile.removeFromParent()
        monster.removeFromParent()
        
        monstersDestroyed++
        if (monstersDestroyed >= 30) {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }

        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
                projectileDidCollideWithMonster(firstBody.node as SKSpriteNode, monster: secondBody.node as SKSpriteNode)
        }
    }
}
