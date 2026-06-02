# Vocalize Project Diagrams

These diagrams replicate the logical structure and flow of the [Major PPT examples](file:///Users/yashitaliya/StudioProjects/vocalize/Major%20PPT.pdf), accurately mapped to the **Vocalize** language learning application entities.

---

## 1. Workflow Diagram
The high-level user journey from onboarding to real-time communication and progress tracking.

```mermaid
graph LR
    User([Learner]) --> Login[Login / Signup]
    Login --> Practice{Choose Activity}
    Practice -- "Flashcards" --> Category[Select Category]
    Category --> PracticeFlow[Identify Word & Audio Practice]
    PracticeFlow --> Favs[Add to Favorites]
    Practice -- "Live Session" --> Match[Matchmaking / Schedule]
    Match --> Video[Video/Audio Call - Agora]
    Video --> Analysis[Call Analysis & Feedback]
    Analysis --> Achievement[Update Achievements / Rank]
    Favs --> Store[(Firebase Firestore)]
    Achievement --> Store
```

---

## 2. Context Level DFD
Defines the external entities and their interactions with the Vocalize System.

```mermaid
graph TD
    subgraph "Vocalize System"
        System(Vocalize App)
    end

    Admin[Admin] -- "Manage Content / Categories" --> System
    Admin -- "Monitor User Reports" --> System
    System -- "System Logs / Analytics" --> Admin

    User[Learner] -- "Request Matching / Join Call" --> System
    User -- "Practice Flashcards / Take Tests" --> System
    System -- "Video Stream / Vocabulary Data" --> User
    System -- "Performance Analysis / Badges" --> User
```

---

## 3. 1st Level DFD (User Side)
Detailed processes mapping user interactions with data stores.

```mermaid
graph TD
    User([User])
    
    User -- "Registration Details" --> P1[1.0 User Registration]
    P1 -- "User Data" --> DB[(User Data Store)]
    
    User -- "Login Credentials" --> P2[2.0 User Login]
    P2 -- "Verify" --> DB
    
    User -- "Search Category" --> P3[3.0 View Vocabulary]
    P3 -- "Fetch Words" --> VocabDB[(Vocabulary Store)]
    
    User -- "Match Request" --> P4[4.0 Matchmaking]
    P4 -- "Join Session" --> SessionDB[(Sessions Store)]
    
    User -- "Test Answers" --> P5[5.0 Take Assessment]
    P5 -- "Store Result" --> TestDB[(Tests Store)]
    
    User -- "Toggle Favorite" --> P6[6.0 Manage Favorites]
    P6 -- "Favorite Word ID" --> FavStore[(Favorites Store)]
```

---

## 4. 1st Level DFD (Admin Side)
Backend processes for administrative control.

```mermaid
graph TD
    Admin([Admin])
    
    Admin -- "User Management Req" --> P1[7.0 Manage Users]
    P1 -- "Fetch/Update Users" --> UserDB[(User Data Store)]
    
    Admin -- "Content Update" --> P2[8.0 Manage Vocabulary]
    P2 -- "Insert/Edit Category" --> VocabDB[(Vocabulary Store)]
    
    Admin -- "Session Review" --> P3[9.0 Monitor Sessions]
    P3 -- "Fetch History" --> SessionDB[(Sessions Store)]
    
    Admin -- "Test Creation" --> P4[10.0 Manage Tests]
    P4 -- "Post Questions" --> TestDB[(Tests Store)]
    
    Admin -- "Bug Report Resolution" --> P5[11.0 Support/Feedback]
    P5 -- "Update Status" --> FeedbackDB[(Feedback Store)]
```

---

## 5. Use Case Diagrams
Visualizing functional requirements for each actor.

### User (Learner) Use Case
```mermaid
graph LR
    Learner((Learner))
    
    Learner --> UC1(Register/Login)
    Learner --> UC2(Manage Profile)
    Learner --> UC3(Practice Vocabulary)
    Learner --> UC4(Add to Favorites)
    Learner --> UC5(Start Direct Call)
    Learner --> UC6(Schedule Session)
    Learner --> UC7(View Translation)
    Learner --> UC8(Track Achievements)

    UC1 -.->|include| UC2
    UC5 -.->|include| UC1
```

### Admin Use Case
```mermaid
graph LR
    AdminStaff((Admin Staff))
    
    AdminStaff --> AUC1(Manage Users)
    AdminStaff --> AUC2(Add Language Pack)
    AdminStaff --> AUC3(Content Moderation)
    AdminStaff --> AUC4(Review Reports)
    AdminStaff --> AUC5(Manage Assessment)
    AdminStaff --> AUC6(View Global Analytics)
```

---

## 6. Database Design (ER Diagram)
Entity relationship mapping for Vocalize's Firestore structure.

```mermaid
erDiagram
    USER ||--o{ FAVORITE : "marks"
    USER ||--o{ SESSION : "participates"
    USER ||--o{ ACHIEVEMENT : "earns"
    CATEGORY ||--o{ VOCABULARY : "contains"
    VOCABULARY ||--o{ FAVORITE : "is marked"
    SESSION ||--|| CALL_ANALYSIS : "generates"
    TEST ||--o{ TEST_RESULT : "produces"
    USER ||--o{ TEST_RESULT : "achieves"

    USER {
        string uid PK
        string name
        string email
        string native_language
        string target_language
        float rating
    }

    VOCABULARY {
        string id PK
        string word
        string translation
        string category_id FK
        string audio_url
    }

    CATEGORY {
        string id PK
        string name
        string image_url
    }

    SESSION {
        string id PK
        string host_id FK
        string guest_id FK
        timestamp start_time
        int duration
    }

    TEST {
        string id PK
        string title
        json questions
    }
```
