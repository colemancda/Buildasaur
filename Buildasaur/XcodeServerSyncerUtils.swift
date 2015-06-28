//
//  XcodeServerSyncerUtils.swift
//  Buildasaur
//
//  Created by Honza Dvorsky on 15/03/2015.
//  Copyright (c) 2015 Honza Dvorsky. All rights reserved.
//

import Foundation
import XcodeServerSDK
import BuildaGitServer
import BuildaUtils

class XcodeServerSyncerUtils {
    
    class func createBotFromBuildTemplate(botName: String, template: BuildTemplate, project: LocalSource, branch: String, scheduleOverride: BotSchedule?, xcodeServer: XcodeServer, completion: (bot: Bot?, error: NSError?) -> ()) {
        
        //pull info from template
        let schemeName = template.scheme!
        
        //optionally override the schedule, if nil, takes it from the template
        let schedule = scheduleOverride ?? template.schedule!
        let cleaningPolicy = template.cleaningPolicy
        let triggers = template.triggers
        let analyze = template.shouldAnalyze ?? false
        let test = template.shouldTest ?? false
        let archive = template.shouldArchive ?? false
        let deviceSpecification = template.deviceSpecification
        let blueprint = project.createSourceControlBlueprint(branch)
        
        //create bot config
        let botConfiguration = BotConfiguration(
            builtFromClean: cleaningPolicy,
            analyze: analyze,
            test: test,
            archive: archive,
            schemeName: schemeName,
            schedule: schedule,
            triggers: triggers,
            deviceSpecification: deviceSpecification,
            sourceControlBlueprint: blueprint)
        
        //create the bot finally
        let newBot = Bot(name: botName, configuration: botConfiguration)
        
        xcodeServer.createBot(newBot, completion: { (response) -> () in
            
            var outBot: Bot?
            var outError: ErrorType?
            switch response {
            case .Success(let bot):
                //we good
                Log.info("Successfully created bot \(bot.name)")
                outBot = bot
                break
            case .Error(let error):
                outError = error
            default:
                outError = Error.withInfo("Failed to return bot after creation even after error was nil!")
            }
            
            //print success/failure etc
            if let error = outError {
                Log.error("Failed to create bot with name \(botName) and json \(newBot.dictionarify()), error \(error)")
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                completion(bot: outBot, error: outError as? NSError)
            })
        })
    }
    
}
