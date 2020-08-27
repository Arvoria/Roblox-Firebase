# ROBLOX-Firebase 1.0.0
ROBLOX-Firebase is a Wrapper module for Firebase's Real-time Database Service utilising its RESTful API. This *only* supports the Real-time Database service, it does not support the Cloud Firestore service at this current time, I may or may not develop a wrapper for the Cloud Firestore service in the future.

While a Firebase wrapper for its Real-time Database already exists I feel as though it did not achieve its full potential without utilising the Batch Update endpoint, it also didn't use ROBLOX's HttpService:RequestAsync(requestOptions) method nor did it use "PATCH" requests for UpdateAsync which, in my opinion was dangerous especially given it defaults to a PUT request.

I also feel as though this much better emulates ROBLOX's DataStoreService and is relatively easy to work with. After using it myself over the last month I am comfortable in saying that this is now my go-to preferred solution for data saving and loading.

## Pointers
- Please, please, please, please write your own caching system for your data and do not call :GetAsync(), :UpdateAsync(), or :BatchUpdateAsync() too often (without a snapshot on the Update methods) as this will cause you to re-download the data and it's descendants from the key provided, this is highly inefficient and if you are using the free-tier plan for Firebase will use up your allocated 10GB/month downloads cap.

- Your caching system would ideally download the database once as a snapshot and only allow it to be downloaded once such that you can utilise it as a snapshot in Update methods and not worry about hitting your downloads cap, but always be sure to keep an eye on it, if your game is popular you may have to upgrade your plan.

- You can get the database in its entirety by calling :GetFirebase(""), a name is expected and cannot be nil so an empty string suffices to get the data and all descendants from the given URL with no name and using the default scope (the url) as the endpoint.

- Always, always be cautious when using :DeleteAsync(), need I say more?

- ROBLOX-Firebase utilises one method internally to modify the Firebase - :SetAsync() - and the other methods are just for your convenience to somewhat automate the process of other actions for you, it also helps in emulating how DataStoreService works.

## Links 
ROBLOX DevForum Post: 
ROBLOX Asset: https://www.roblox.com/library/5618676786/Roblox-Firebase (To be used in require(assetId) calls)

## Contact
You can contact me on Discord @Shane#3756 for any queries you may have or if any issues arise. There may be a few edge cases I have missed and/or either handled poorly or not at all.