/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBListApplicationsConfiguration.h"

#import "FBiOSTarget.h"
#import "FBSubject.h"
#import "FBControlCoreError.h"
#import "FBApplicationCommands.h"

FBiOSTargetActionType const FBiOSTargetActionTypeListApplications = @"list_apps";

@implementation FBListApplicationsConfiguration

#pragma mark FBiOSTargetFuture

- (FBiOSTargetActionType)actionType
{
  return FBiOSTargetActionTypeListApplications;
}

- (FBFuture<FBiOSTargetActionType> *)runWithTarget:(id<FBiOSTarget>)target consumer:(id<FBFileConsumer>)consumer reporter:(id<FBEventReporter>)reporter
{
  id<FBApplicationCommands> commands = (id<FBApplicationCommands>) target;
  if (![target conformsToProtocol:@protocol(FBApplicationCommands)]) {
    return [[FBControlCoreError
      describeFormat:@"%@ does not support FBApplicationCommands", target]
      failFuture];
  }
  return [[[commands
    installedApplications]
    onQueue:target.workQueue notifyOfCompletion:^(FBFuture<NSArray<FBInstalledApplication *> *> *future) {
      NSArray<id<FBJSONSerializable>> *values = (NSArray<id<FBJSONSerializable>> *) future.result;
      if (!values) {
        return;
      }
      id<FBEventReporterSubject> subject = [FBEventReporterSubject subjectWithName:FBEventNameListApps type:FBEventTypeDiscrete values:values];
      [reporter report:subject];
    }]
    mapReplace:self.actionType];
}

@end