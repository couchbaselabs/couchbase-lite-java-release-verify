package com.example.cblverify;  
  
import com.couchbase.lite.*;  
import org.junit.jupiter.api.*;  
  
import java.io.File;  
import java.nio.file.Files;  
import java.util.Date;  
  
import static org.junit.jupiter.api.Assertions.*;  
  
/**  
 * Verification tests for Couchbase Lite Java  
 * Tests basic database operations, CRUD, queries, and replication setup  
 */  
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)  
public class CouchbaseLiteVerifyTest {  
      
    private static final String DB_NAME = "testdb";  
    private static Database database;  
    private static Collection collection;  
    private static File tempDir;  
      
    @BeforeAll  
    public static void setUpClass() throws Exception {  
        // Initialize Couchbase Lite  
        tempDir = Files.createTempDirectory("cbl-test").toFile();  
        tempDir.deleteOnExit();  
          
        CouchbaseLite.init();  
          
        System.out.println("Couchbase Lite initialized");  
        System.out.println("Test directory: " + tempDir.getAbsolutePath());  
    }  
      
    @AfterAll  
    public static void tearDownClass() throws Exception {  
        // Cleanup  
        if (database != null) {  
            database.close();  
        }  
        
        if (tempDir != null && tempDir.exists()) {  
            deleteDirectory(tempDir);  
        }  
    }
      
    @BeforeEach  
    public void setUp() throws CouchbaseLiteException {  
        // Create database  
        DatabaseConfiguration config = new DatabaseConfiguration();  
        config.setDirectory(tempDir.getAbsolutePath());  
        database = new Database(DB_NAME, config);  
          
        // Get the default collection  
        collection = database.getDefaultCollection();  
          
        System.out.println("Database created: " + database.getName());  
    }  
      
    @AfterEach  
    public void tearDown() throws CouchbaseLiteException {  
        if (database != null) {  
            database.delete();  
            database = null;  
            collection = null;  
        }  
    }  
      
    @Test  
    @Order(1)  
    @DisplayName("Test Database Creation")  
    public void testDatabaseCreation() {  
        assertNotNull(database, "Database should not be null");  
        assertEquals(DB_NAME, database.getName(), "Database name should match");  
        assertTrue(database.getPath().contains(tempDir.getAbsolutePath()),   
                   "Database path should be in temp directory");  
          
        System.out.println("Database creation test passed");  
    }  
      
    @Test  
    @Order(2)  
    @DisplayName("Test Document CRUD Operations")  
    public void testDocumentCRUD() throws CouchbaseLiteException {  
        // CREATE  
        String docId = "test-doc-1";  
        MutableDocument doc = new MutableDocument(docId);  
        doc.setString("type", "test");  
        doc.setString("name", "Test Document");  
        doc.setInt("version", 1);  
        doc.setDate("timestamp", new Date());  
        doc.setBoolean("active", true);  
          
        collection.save(doc);  
        assertEquals(1, collection.getCount(), "Collection should have 1 document");  
          
        // READ  
        Document savedDoc = collection.getDocument(docId);  
        assertNotNull(savedDoc, "Saved document should exist");  
        assertEquals("test", savedDoc.getString("type"));  
        assertEquals("Test Document", savedDoc.getString("name"));  
        assertEquals(1, savedDoc.getInt("version"));  
        assertTrue(savedDoc.getBoolean("active"));  
          
        // UPDATE  
        MutableDocument mutableDoc = savedDoc.toMutable();  
        mutableDoc.setInt("version", 2);  
        mutableDoc.setString("name", "Updated Test Document");  
        collection.save(mutableDoc);  
          
        Document updatedDoc = collection.getDocument(docId);  
        assertEquals(2, updatedDoc.getInt("version"));  
        assertEquals("Updated Test Document", updatedDoc.getString("name"));  
          
        // DELETE  
        collection.delete(updatedDoc);  
        assertNull(collection.getDocument(docId), "Document should be deleted");  
        assertEquals(0, collection.getCount(), "Collection should be empty");  
          
        System.out.println("Document CRUD test passed");  
    }  
      
    @Test  
    @Order(3)  
    @DisplayName("Test Batch Operations")  
    public void testBatchOperations() throws CouchbaseLiteException {  
        final int DOC_COUNT = 100;  
          
        database.inBatch(() -> {  
            for (int i = 0; i < DOC_COUNT; i++) {  
                MutableDocument doc = new MutableDocument("doc-" + i);  
                doc.setString("type", "batch-test");  
                doc.setInt("index", i);  
                doc.setString("data", "Test data for document " + i);  
                collection.save(doc);  
            }  
        });  
          
        assertEquals(DOC_COUNT, collection.getCount(),   
                     "Collection should have " + DOC_COUNT + " documents");  
          
        System.out.println("Batch operations test passed - created " + DOC_COUNT + " documents");  
    }  
      
    @Test  
    @Order(4)  
    @DisplayName("Test Query Operations")  
    public void testQueryOperations() throws CouchbaseLiteException {  
        // Create test documents  
        for (int i = 0; i < 10; i++) {  
            MutableDocument doc = new MutableDocument("query-doc-" + i);  
            doc.setString("type", "query-test");  
            doc.setInt("value", i * 10);  
            doc.setBoolean("even", i % 2 == 0);  
            collection.save(doc);  
        }  
          
        // Query all documents of type "query-test"  
        Query query = QueryBuilder  
            .select(SelectResult.expression(Meta.id),  
                    SelectResult.property("value"))  
            .from(DataSource.collection(collection))  
            .where(Expression.property("type").equalTo(Expression.string("query-test")));  
          
        try (ResultSet results = query.execute()) {  
            int count = 0;  
            for (Result result : results) {  
                assertNotNull(result.getString(0)); // document ID  
                assertNotNull(result.getValue("value"));  
                count++;  
            }  
            assertEquals(10, count, "Query should return 10 documents");  
        }  
          
        // Query with WHERE clause  
        Query whereQuery = QueryBuilder  
            .select(SelectResult.all())  
            .from(DataSource.collection(collection))  
            .where(Expression.property("even").equalTo(Expression.booleanValue(true)));  
          
        try (ResultSet results = whereQuery.execute()) {  
            int count = 0;  
            for (Result result : results) {  
                count++;  
            }  
            assertEquals(5, count, "Query should return 5 even documents");  
        }  
          
        System.out.println("Query operations test passed");  
    }  
      
    @Test  
    @Order(5)  
    @DisplayName("Test Index Creation")  
    public void testIndexCreation() throws CouchbaseLiteException {  
        // Create value index  
        collection.createIndex("typeIndex",   
            IndexBuilder.valueIndex(ValueIndexItem.property("type")));  
          
        // Create FTS index  
        collection.createIndex("textIndex",  
            IndexBuilder.fullTextIndex(FullTextIndexItem.property("name")));  
          
        // Verify indexes exist  
        assertTrue(collection.getIndexes().contains("typeIndex"),   
                   "Value index should exist");  
        assertTrue(collection.getIndexes().contains("textIndex"),   
                   "FTS index should exist");  
          
        System.out.println("Index creation test passed");  
    }  
      
    @Test  
    @Order(6)  
    @DisplayName("Test Blob Operations")  
    public void testBlobOperations() throws CouchbaseLiteException {  
        byte[] content = "This is a test blob content".getBytes();  
        Blob blob = new Blob("text/plain", content);  
          
        MutableDocument doc = new MutableDocument("blob-doc");  
        doc.setBlob("attachment", blob);  
        doc.setString("type", "blob-test");  
          
        collection.save(doc);  
          
        Document savedDoc = collection.getDocument("blob-doc");  
        Blob savedBlob = savedDoc.getBlob("attachment");  
          
        assertNotNull(savedBlob, "Blob should not be null");  
        assertEquals("text/plain", savedBlob.getContentType());  
        assertArrayEquals(content, savedBlob.getContent());  
          
        System.out.println("Blob operations test passed");  
    }  
      
    @Test  
    @Order(7)  
    @DisplayName("Test Database Configuration")  
    public void testDatabaseConfiguration() throws CouchbaseLiteException {  
        DatabaseConfiguration config = database.getConfig();  
          
        assertNotNull(config, "Database config should not be null");  
        assertNotNull(config.getDirectory(), "Config directory should not be null");  
          
        System.out.println("Database configuration test passed");  
        System.out.println("  Directory: " + config.getDirectory());  
    }  
      
    // Helper method to delete directory recursively  
    private static void deleteDirectory(File directory) {  
        File[] files = directory.listFiles();  
        if (files != null) {  
            for (File file : files) {  
                if (file.isDirectory()) {  
                    deleteDirectory(file);  
                } else {  
                    file.delete();  
                }  
            }  
        }  
        directory.delete();  
    }  
}