---
sidebar_position: 5
---
# Optimization

Don't forget you can always use the Debug attribute to open a runtime editor where you can see details on certain things! (Only in studio)

## Root Objects
SmartBone attempts to optomize using root objects with 2 methods, checking if the object is on screen and throttling the update rate. You will want to make sure your root object is the correct size for your mesh if its too small or too big then SmartBone will incorrectly assume its off screen or on screen, throttling update rate is controlled via the attributes: ActivationDistance and ThrottleDistance on the root object.

## Bones
You will want to use the minimum amount of bones you can to achieve a pleasing effect, the more bones the longer it will take for SmartBone to update.

## Colliders
The time complexity for colliders is **O(nm)** where n is the number of active colliders and m is the number of global bones, a few notes: Colliders which arent a descendant of workspace are not calculated and colliders are only calculated by objects within their sphere of influence. The collider type also contributes, spheres are by far the easiest shape to calculate then box, capsule and cylinder. I doubt it will be a noticeable hit but if your seeing a big performance hit with these then try and optomize your collider use. Don't forget to use collider keys if you have alot of colliders!

## Constraints
Smartbone 2 offers a choice between a Spring constraint and a Distance constraint because of this if you are really short for performance then you can switch to a Distance constraint its calculation is fewer operations compared to the Spring constraint which takes longer to compute (Not that much longer but if you really want to get those microseconds out then go ahead). If you can, then try and use AxisConstraints instead of colliders, since they're local to the bone their time complexity is **O(n)** where n is the number of axis limits maximum of 6.

## Wind
If you want an object to have no wind influence, instead of just setting WindInfluence to 0 set the WindType attribute to an empty string, this will bypass all of the wind calculations and could possibly shave off a few ms.

## Roblox Issues
If Roblox allowed us to read TransformedWorldCFrame in parallel I'm guessing there could be a performance increase of about 1.5x, if Roblox also added something for BulkPropertySet where you could set any property without firing signals that would also be amazingly beneficial.
