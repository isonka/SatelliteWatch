import Foundation

enum SpaceXJSONFixtures {
    static let populatedLaunchPage = """
    {
      "docs": [
        {
          "id": "launch-1",
          "name": "CRS-20",
          "details": "Resupply mission",
          "success": true,
          "upcoming": false,
          "date_utc": "2020-03-07T04:50:31.000Z",
          "date_precision": "hour",
          "links": {
            "patch": {
              "small": "https://example.com/small.png",
              "large": "https://example.com/large.png"
            },
            "webcast": "https://www.youtube.com/watch?v=abc"
          },
          "rocket": {
            "id": "falcon9",
            "name": "Falcon 9",
            "type": "rocket",
            "active": true,
            "description": "Reusable rocket",
            "success_rate_pct": 97,
            "flickr_images": ["https://example.com/rocket.jpg"],
            "engines": { "number": 9, "type": "merlin", "version": "1D+" }
          },
          "launchpad": {
            "id": "ccafs_slc_40",
            "name": "CCAFS SLC 40",
            "full_name": "Cape Canaveral Air Force Station Space Launch Complex 40",
            "locality": "Cape Canaveral",
            "region": "Florida"
          }
        }
      ],
      "totalDocs": 1,
      "limit": 20,
      "totalPages": 1,
      "page": 1,
      "hasNextPage": false,
      "hasPrevPage": false,
      "nextPage": null,
      "prevPage": null
    }
    """.data(using: .utf8)!

    static let launchWithIDReferences = """
    {
      "id": "launch-2",
      "name": "Future Mission",
      "details": null,
      "success": null,
      "upcoming": true,
      "date_utc": "2030-01-01T00:00:00.000Z",
      "date_precision": "month",
      "links": {
        "patch": { "small": null, "large": null },
        "webcast": "not-a-url"
      },
      "rocket": "falcon9",
      "launchpad": "ksc"
    }
    """.data(using: .utf8)!

    static let rocketPage = """
    {
      "docs": [
        {
          "id": "falcon9",
          "name": "Falcon 9",
          "type": "rocket",
          "active": true,
          "description": "Two-stage rocket",
          "success_rate_pct": 98,
          "flickr_images": ["https://example.com/f9.jpg"],
          "engines": { "number": 9, "type": "merlin", "version": "1D+" }
        }
      ],
      "totalDocs": 1,
      "limit": 20,
      "totalPages": 1,
      "page": 1,
      "hasNextPage": false,
      "hasPrevPage": false,
      "nextPage": null,
      "prevPage": null
    }
    """.data(using: .utf8)!
}
