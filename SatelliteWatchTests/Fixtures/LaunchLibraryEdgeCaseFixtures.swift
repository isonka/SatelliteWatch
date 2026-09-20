import Foundation

enum LaunchLibraryEdgeCaseFixtures {
    static let launchesWithUnknownStatusIDs = """
    {
      "results": [
        {
          "id": "abbrev-success",
          "name": "Abbrev Success",
          "net": "2024-02-01T10:00:00Z",
          "image": null,
          "status": { "id": 99, "abbrev": "Success" },
          "net_precision": { "abbrev": "DAY" },
          "rocket": null,
          "mission": null,
          "pad": null,
          "program": null
        },
        {
          "id": "abbrev-failure",
          "name": "Abbrev Failure",
          "net": "2024-02-02T10:00:00Z",
          "image": null,
          "status": { "id": 99, "abbrev": "Failure" },
          "net_precision": { "abbrev": "DAY" },
          "rocket": null,
          "mission": null,
          "pad": null,
          "program": null
        },
        {
          "id": "abbrev-partial",
          "name": "Abbrev Partial Failure",
          "net": "2024-02-03T10:00:00Z",
          "image": null,
          "status": { "id": null, "abbrev": "partial failure" },
          "net_precision": { "abbrev": "DAY" },
          "rocket": null,
          "mission": null,
          "pad": null,
          "program": null
        },
        {
          "id": "abbrev-unknown",
          "name": "Abbrev Unknown",
          "net": "2024-02-04T10:00:00Z",
          "image": null,
          "status": { "id": 99, "abbrev": "TBD" },
          "net_precision": null,
          "rocket": null,
          "mission": null,
          "pad": null,
          "program": null
        }
      ]
    }
    """
    
    static let launchesWithFailureStatusIDs = """
    {
      "results": [
        {
          "id": "status-4",
          "name": "Launch Failure",
          "net": "2024-03-01T10:00:00Z",
          "image": null,
          "status": { "id": 4, "abbrev": "Failure" },
          "net_precision": { "abbrev": "DAY" },
          "rocket": null,
          "mission": null,
          "pad": null,
          "program": null
        },
        {
          "id": "status-7",
          "name": "Partial Failure",
          "net": "2024-03-02T10:00:00Z",
          "image": null,
          "status": { "id": 7, "abbrev": "Partial Failure" },
          "net_precision": { "abbrev": "DAY" },
          "rocket": null,
          "mission": null,
          "pad": null,
          "program": null
        }
      ]
    }
    """

    static let launchesWithoutUsablePads = """
    {
      "results": [
        {
          "id": "pad-missing",
          "name": "No Pad",
          "net": "2024-04-01T10:00:00Z",
          "image": null,
          "status": { "id": 3, "abbrev": "Success" },
          "net_precision": { "abbrev": "DAY" },
          "rocket": null,
          "mission": null,
          "pad": null,
          "program": null
        },
        {
          "id": "pad-empty",
          "name": "Empty Pad",
          "net": "2024-04-02T10:00:00Z",
          "image": null,
          "status": { "id": 3, "abbrev": "Success" },
          "net_precision": { "abbrev": "DAY" },
          "rocket": null,
          "mission": null,
          "pad": { "id": null, "name": null, "wiki_url": null, "location": null },
          "program": null
        }
      ]
    }
    """

    static let launchesWithCompetingPatches = """
    {
      "results": [
        {
          "id": "patch-priority",
          "name": "Priority Patch",
          "net": "2024-05-01T10:00:00Z",
          "image": "https://example.com/fallback.png",
          "status": { "id": 3, "abbrev": "Success" },
          "net_precision": { "abbrev": "DAY" },
          "rocket": null,
          "mission": null,
          "pad": null,
          "program": [
            {
              "mission_patches": [
                { "priority": 1, "image_url": "https://example.com/low.png" },
                { "priority": 50, "image_url": "https://example.com/high.png" }
              ]
            }
          ]
        },
        {
          "id": "patch-fallback",
          "name": "Fallback Image",
          "net": "2024-05-02T10:00:00Z",
          "image": "https://example.com/fallback.png",
          "status": { "id": 3, "abbrev": "Success" },
          "net_precision": { "abbrev": "DAY" },
          "rocket": null,
          "mission": null,
          "pad": null,
          "program": [{ "mission_patches": [] }]
        }
      ]
    }
    """

    static let rocketsWithUncomputableSuccessRate = """
    {
      "results": [
        {
          "id": 900,
          "name": "Never Flown",
          "full_name": null,
          "family": null,
          "description": null,
          "active": false,
          "image_url": null,
          "total_launch_count": 0,
          "successful_launches": 0
        },
        {
          "id": 901,
          "name": "Unknown Total",
          "full_name": null,
          "family": null,
          "description": null,
          "active": null,
          "image_url": null,
          "total_launch_count": null,
          "successful_launches": 5
        },
        {
          "id": 902,
          "name": "Unknown Successes",
          "full_name": null,
          "family": null,
          "description": null,
          "active": true,
          "image_url": null,
          "total_launch_count": 12,
          "successful_launches": null
        }
      ]
    }
    """
}
