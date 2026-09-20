import Foundation

enum SpaceXJSONFixtures {
    static let rocket = """
    {
      "id": "5e9d0d95eda69973a809d1ec",
      "name": "Falcon 9",
      "type": "rocket",
      "active": true,
      "description": "Falcon 9 is a two-stage rocket designed and manufactured by SpaceX.",
      "success_rate_pct": 98,
      "flickr_images": [
        "https://farm1.staticflickr.com/929/28760836339_a04b3d9d14_b.jpg"
      ],
      "engines": {
        "number": 9,
        "type": "merlin",
        "version": "1D+"
      }
    }
    """

    static let rocketPage = """
    {
      "docs": [\(rocket)],
      "totalDocs": 1,
      "limit": 20,
      "totalPages": 1,
      "page": 1,
      "pagingCounter": 1,
      "hasPrevPage": false,
      "hasNextPage": false,
      "prevPage": null,
      "nextPage": null
    }
    """

    static let populatedLaunchPage = """
    {
      "docs": [
        {
          "id": "5eb87d46ffd86e000604b388",
          "name": "Starlink-15 (v1.0)",
          "details": "SpaceX will launch more Starlink satellites.",
          "success": true,
          "upcoming": false,
          "date_utc": "2020-10-24T15:31:00.000Z",
          "date_precision": "hour",
          "links": {
            "patch": {
              "small": "https://images2.imgbox.com/9a/96/nLpmhWDJ_o.png",
              "large": "https://images2.imgbox.com/d2/3b/bQaWiVQ0_o.png"
            },
            "webcast": "https://youtu.be/J442-ti-Dhg",
            "wikipedia": "https://en.wikipedia.org/wiki/Starlink",
            "article": null
          },
          "rocket": \(rocket),
          "launchpad": {
            "id": "5e9e4502f509094188566f88",
            "name": "KSC LC 39A",
            "full_name": "Kennedy Space Center Historic Launch Complex 39A",
            "locality": "Cape Canaveral",
            "region": "Florida"
          }
        }
      ],
      "totalDocs": 1,
      "limit": 20,
      "totalPages": 1,
      "page": 1,
      "hasPrevPage": false,
      "hasNextPage": false,
      "prevPage": null,
      "nextPage": null
    }
    """

    static let launchWithIDReferences = """
    {
      "docs": [
        {
          "id": "5eb87d46ffd86e000604b388",
          "name": "Starlink-15 (v1.0)",
          "details": null,
          "success": true,
          "upcoming": false,
          "date_utc": "2020-10-24T15:31:00.000Z",
          "date_precision": "hour",
          "links": null,
          "rocket": "5e9d0d95eda69973a809d1ec",
          "launchpad": "5e9e4502f509094188566f88"
        }
      ],
      "totalDocs": 1,
      "limit": 20,
      "totalPages": 1,
      "page": 1,
      "hasPrevPage": false,
      "hasNextPage": false,
      "prevPage": null,
      "nextPage": null
    }
    """

    static let multiPageRocketsPage1 = """
    {
      "docs": [
        {
          "id": "rocket-a",
          "name": "Rocket A",
          "type": "rocket",
          "active": true,
          "description": null,
          "success_rate_pct": null,
          "flickr_images": [],
          "engines": null
        },
        {
          "id": "rocket-b",
          "name": "Rocket B",
          "type": "rocket",
          "active": false,
          "description": null,
          "success_rate_pct": null,
          "flickr_images": [],
          "engines": null
        }
      ],
      "totalDocs": 3,
      "limit": 2,
      "totalPages": 2,
      "page": 1,
      "hasPrevPage": false,
      "hasNextPage": true,
      "prevPage": null,
      "nextPage": 2
    }
    """

    static let multiPageRocketsPage2 = """
    {
      "docs": [
        {
          "id": "rocket-c",
          "name": "Rocket C",
          "type": "rocket",
          "active": true,
          "description": null,
          "success_rate_pct": null,
          "flickr_images": [],
          "engines": null
        }
      ],
      "totalDocs": 3,
      "limit": 2,
      "totalPages": 2,
      "page": 2,
      "hasPrevPage": true,
      "hasNextPage": false,
      "prevPage": 1,
      "nextPage": null
    }
    """
}

enum LaunchLibraryJSONFixtures {
    static let upcomingLaunches = """
    {
      "results": [
        {
          "id": "upcoming-1",
          "name": "Crew-11",
          "net": "2025-06-01T12:00:00Z",
          "image": "https://example.com/crew.png",
          "status": { "id": 1, "abbrev": "TBD" },
          "net_precision": { "abbrev": "HOUR" },
          "rocket": {
            "configuration": { "id": 164, "name": "Falcon 9", "full_name": "Falcon 9 Block 5" }
          },
          "mission": {
            "description": "Crew rotation",
            "info_urls": ["https://example.com/info"],
            "vid_urls": [{ "url": "https://example.com/vid" }]
          },
          "pad": {
            "id": 87,
            "name": "LC-39A",
            "wiki_url": "https://en.wikipedia.org/wiki/Kennedy_Space_Center_Launch_Complex_39",
            "location": { "name": "Cape Canaveral", "country_code": "USA" }
          },
          "program": []
        }
      ]
    }
    """

    static let previousLaunches = """
    {
      "results": [
        {
          "id": "previous-1",
          "name": "Starlink Group 6-1",
          "net": "2024-01-15T10:00:00Z",
          "image": null,
          "status": { "id": 3, "abbrev": "Success" },
          "net_precision": { "abbrev": "DAY" },
          "rocket": {
            "configuration": { "id": 164, "name": "Falcon 9", "full_name": "Falcon 9 Block 5" }
          },
          "mission": {
            "description": "Starlink mission",
            "info_urls": null,
            "vid_urls": null
          },
          "pad": {
            "id": 80,
            "name": "SLC-40",
            "wiki_url": null,
            "location": { "name": "Cape Canaveral", "country_code": "USA" }
          },
          "program": [
            {
              "mission_patches": [
                { "priority": 10, "image_url": "https://example.com/patch.png" }
              ]
            }
          ]
        },
        {
          "id": "upcoming-1",
          "name": "Crew-11 (overlap stale)",
          "net": "2025-06-01T12:00:00Z",
          "image": null,
          "status": { "id": 3, "abbrev": "Success" },
          "net_precision": { "abbrev": "HOUR" },
          "rocket": {
            "configuration": { "id": 164, "name": "Falcon 9", "full_name": "Falcon 9 Block 5" }
          },
          "mission": { "description": null, "info_urls": null, "vid_urls": null },
          "pad": {
            "id": 87,
            "name": "LC-39A",
            "wiki_url": null,
            "location": { "name": "Cape Canaveral", "country_code": "USA" }
          },
          "program": []
        }
      ]
    }
    """

    static let rockets = """
    {
      "results": [
        {
          "id": 164,
          "name": "Falcon 9",
          "full_name": "Falcon 9 Block 5",
          "family": "Falcon",
          "description": "Reusable medium-lift rocket.",
          "active": true,
          "image_url": "https://example.com/f9.jpg",
          "total_launch_count": 100,
          "successful_launches": 98
        },
        {
          "id": 188,
          "name": "Falcon Heavy",
          "full_name": "Falcon Heavy",
          "family": "Falcon",
          "description": null,
          "active": true,
          "image_url": null,
          "total_launch_count": 10,
          "successful_launches": 10
        }
      ]
    }
    """
}
