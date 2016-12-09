import java.io.InputStream;
import java.io.FileInputStream
import java.io.File;
import javax.xml.transform.stream.StreamSource

def hudson = hudson.model.Hudson.instance;

//to get a single job
//def job = hudson.model.Hudson.instance.getItem('my-job');

for(job in hudson.model.Hudson.instance.items) {   

    if (job.name == "my-job") {

        def configXMLFile = job.getConfigFile();
        def file = configXMLFile.getFile();

        InputStream is = new FileInputStream(file);

        job.updateByXml(new StreamSource(is));
        job.save();         
    }      
} 

