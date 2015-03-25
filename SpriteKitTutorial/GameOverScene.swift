//
//  GameOverScene.swift
//  SpriteKitTutorial
//
//  Created by Bui Van Hung on 3/25/15.
//  Copyright (c) 2015 com.framgia. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    
    init(size: CGSize, won:Bool) {
        
        super.init(size: size)
        // Set màu cho background
        backgroundColor = SKColor.whiteColor()
        // Set nội dung cho message màn là thắng hoặc thua dựa vào kết quả của người chơi
        var message = won ? "You Won!" : "You Lose!"
        // config chữ, font và màu chữ cho message thông báo
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.blackColor()
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        // 1
        runAction(SKAction.sequence([
            SKAction.waitForDuration(3.0),
            SKAction.runBlock() {
                // 2
                let reveal = SKTransition.flipHorizontalWithDuration(0.5)
                let scene = GameScene(size: size)
                self.view?.presentScene(scene, transition:reveal)
            }
            ]))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}