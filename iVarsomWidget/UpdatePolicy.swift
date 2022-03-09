import Foundation

/**
 Returns the next point in time to generate a new timeline for the widget based on the previous and current warning.
 
 The Varsom API returns four date fields for each warning: `PublishTime`, `NextWarningTime`, `ValidFrom`, and `ValidTo`.
 
 Typically, the warnings are published every day around ~16:00, and a given warning is valid until midnight.
 This is an example of the data for 9th of March 2022:
 
 ```
 <AvalancheWarningSimple>
    <DangerLevel>2</DangerLevel>
    <MainText>Use caution in steep terrain with wind slabs. </MainText>
    <NextWarningTime>2022-03-10T16:00:00</NextWarningTime>
    <PublishTime>2022-03-08T15:33:17.63</PublishTime>
    <RegionId>3022</RegionId>
    <ValidFrom>2022-03-09T00:00:00</ValidFrom>
    <ValidTo>2022-03-09T23:59:59</ValidTo>
 </AvalancheWarningSimple>
 ```
 As you can see from the `PublishTime` the warning was issued on the previous day, 8th of March, at 15:33.
 The `NextWarningTime` is at 16:00 the next day. So to determine the ideal time to update the widget, with the least
 amount of updates, we need to look at the `NextWarningTime` of the previous day which would be `2022-03-09T16:00:00` and
 the `ValidTo` of the current date which is `2022-03-09T23:59:59`.
 
 The timeline refresh would then be scheduled to run at:
 
 * `2022-03-09T00:00:59`, one minute after `ValidTo`
 * `2022-03-09T16:00:00`, the `NextWarningTime`
 * `2022-03-10T00:00:59` one minute after `ValidTo` for the next day
 
 - Precondition: The `prevWarning` must be for the day before `currentWarning`
 - Invariant: The return value is allways a `Date` in the future to avoid starvation of the timeline
 
 - Parameters:
    - prevWarning: The previous day warning
    - currentWarning: The current day warning
 
 - Returns: A new `Date` to be used for the `.after` update policy of the timeline.
*/
func getNextUpdateTime(prevWarning: AvalancheWarningSimple, currentWarning: AvalancheWarningSimple) -> Date {
    var afterDate = prevWarning.NextWarningTime
    
    // If the next warning time (16:00 today) has expired, then use the ValidTo for update.
    if afterDate < Date() {
        afterDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentWarning.ValidTo)!
    }
    
    // If the ValidTo has expired, update again in one hour.
    if afterDate < Date() {
        afterDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    }

    return afterDate
}
