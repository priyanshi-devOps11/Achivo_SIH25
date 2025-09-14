-- Create tables for users (students and HODs)
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    father_name VARCHAR(100),
    password VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'STUDENT',
    department VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert CS Branch Students
INSERT INTO users (user_id, name, father_name, password, role, department) VALUES
('100230101', 'AADITYA GAUR', 'ANURAG GAUR', 'AADITYA7429', 'STUDENT', 'CS'),
('100230102', 'ABHINAV YADAV', 'SHAITAN SINGH', 'ABHINAV2847', 'STUDENT', 'CS'),
('100230103', 'ABHISEKH KUMAR', 'KULDEEP KUMAR', 'ABHISEKH9156', 'STUDENT', 'CS'),
('100230104', 'ABHISHEK BIND', 'BABLU BIND', 'ABHISHEK3842', 'STUDENT', 'CS'),
('100230105', 'ABHISHEK KUMAR', 'MANOJ KUMAR', 'ABHISHEK6591', 'STUDENT', 'CS'),
('100230106', 'ABHISHEK TIWARI', 'AMBRISH TIWARI', 'ABHISHEK1729', 'STUDENT', 'CS'),
('100230107', 'ADITI SHUKLA', 'UMAKANT SHUKLA', 'ADITI8463', 'STUDENT', 'CS'),
('100230108', 'ADITYA KUMAR PRASAD', 'DIN DAYAL PRASAD', 'ADITYA5927', 'STUDENT', 'CS'),
('100230109', 'ADITYA YADAV', 'MAHENDRA SINGH YADAV', 'ADITYA4185', 'STUDENT', 'CS'),
('100230110', 'AGAM PATHAK', 'YATENDRA PATHAK', 'AGAM7638', 'STUDENT', 'CS'),
('100230111', 'AKARSHIT SHARMA', 'AJAY KUMAR SHARMA', 'AKARSHIT9274', 'STUDENT', 'CS'),
('100230112', 'ANAND CHAUDHARY', 'PRAMATMA PRASAD CHAUDHARY', 'ANAND5816', 'STUDENT', 'CS'),
('100230113', 'ANANYA TYAGI', 'SANDEEP TYAGI', 'ANANYA3492', 'STUDENT', 'CS'),
('100230114', 'ANAY AGARWAL', 'NEERAJ AGARWAL', 'ANAY7051', 'STUDENT', 'CS'),
('100230115', 'ANKIT KUMAR', 'BANIPAL SINGH', 'ANKIT8369', 'STUDENT', 'CS'),
('100230116', 'APOORVATA JAISAWAL', 'GYAN CHAND JAISAWAL', 'APOORVATA2745', 'STUDENT', 'CS'),
('100230117', 'AQIB', 'ABID', 'AQIB6128', 'STUDENT', 'CS'),
('100230118', 'ARPIT BALIYAN', 'AMIT KUMAR', 'ARPIT4967', 'STUDENT', 'CS'),
('100230119', 'ARPIT KUMAR', 'NARENDRA KUMAR', 'ARPIT1583', 'STUDENT', 'CS'),
('100230120', 'ARPIT KUMAR VERMA', 'MOOL CHANDRA', 'ARPIT9204', 'STUDENT', 'CS'),
('100230121', 'ARPIT KUMAR VERMA', 'RAJESH KUMAR VERMA', 'ARPIT7456', 'STUDENT', 'CS'),
('100230122', 'ARYAN SINGH', 'NAGENDAR KUMAR SINGH', 'ARYAN3819', 'STUDENT', 'CS'),
('100230123', 'ASHISH GUPTA', 'RAJESH KUMAR', 'ASHISH6042', 'STUDENT', 'CS'),
('100230124', 'AVSHESH BHARTIYA', 'ANAND PRAKASH BHARITYA', 'AVSHESH2587', 'STUDENT', 'CS'),
('100230125', 'CHETAN CHAUHAN', 'UPDESH CHAUHAN', 'CHETAN8731', 'STUDENT', 'CS'),
('100230126', 'DAMINI', 'YASHPAL SINGH', 'DAMINI4965', 'STUDENT', 'CS'),
('100230127', 'DEVANSH RASTOGI', 'BRIJESH KUMAR RASTOGI', 'DEVANSH1248', 'STUDENT', 'CS'),
('100230128', 'DHRUVE KAPIL', 'PUNEET KAPIL', 'DHRUVE7893', 'STUDENT', 'CS'),
('100230129', 'DIVYA RAJPUT', 'JAIDRATH SINGH', 'DIVYA5416', 'STUDENT', 'CS'),
('100230130', 'DOLLY', 'RATAN LAL', 'DOLLY3072', 'STUDENT', 'CS'),
('100230131', 'DURGESH KUMAR YADAV', 'HARISHCHANDRA YADAV', 'DURGESH9685', 'STUDENT', 'CS'),
('100230132', 'DUSHYANT', 'SUKHPAL SINGH', 'DUSHYANT1357', 'STUDENT', 'CS'),
('100230133', 'GAURANG', 'CHANDRA PRAKASH VERMA', 'GAURANG8420', 'STUDENT', 'CS'),
('100230134', 'GAURAV KUMAR', 'HARSWAROOP SINGH', 'GAURAV6194', 'STUDENT', 'CS'),
('100230135', 'GYAN CHANDRA', 'UMA SHANKAR', 'GYAN2758', 'STUDENT', 'CS'),
('100230136', 'HARENDRA PAL SINGH', 'CHANDRA PAL SINGH', 'HARENDRA4631', 'STUDENT', 'CS'),
('100230137', 'HIMANSHU KUMAR', 'PRADEEP KUMAR', 'HIMANSHU9073', 'STUDENT', 'CS'),
('100230138', 'HIMANSHU UPADHEYAY', 'RADHE KRISHAN UPADHEYAY', 'HIMANSHU5297', 'STUDENT', 'CS'),
('100230139', 'JEETU PAL', 'NEELESH KUMAR', 'JEETU7864', 'STUDENT', 'CS'),
('100230140', 'JITENDRA KUMAR', 'MUKAT SINGH', 'JITENDRA1528', 'STUDENT', 'CS'),
('100230141', 'KAJAL RANI', 'CHAND KIRAN', 'KAJAL8392', 'STUDENT', 'CS'),
('100230142', 'KAMINI', 'KULBIR SINGH', 'KAMINI4756', 'STUDENT', 'CS'),
('100230143', 'KASAK', 'PAWAN', 'KASAK2019', 'STUDENT', 'CS'),
('100230144', 'KAUSHAL RAJ VERMA', 'PRAMOD KUMAR', 'KAUSHAL6483', 'STUDENT', 'CS'),
('100230145', 'KAVITA CHAUHAN', 'RAMESH CHAUHAN', 'KAVITA3147', 'STUDENT', 'CS'),
('100230146', 'KHUSHI TYAGI', 'SANDEEP TYAGI', 'KHUSHI9701', 'STUDENT', 'CS'),
('100230147', 'KULDEEP RATHORE', 'DINESH CHANDRA RATHORE', 'KULDEEP5268', 'STUDENT', 'CS'),
('100230148', 'MANISH GUPTA', 'BABLU GUPTA', 'MANISH8534', 'STUDENT', 'CS'),
('100230149', 'MANISH KUMAR', 'RAMESH KUMAR', 'MANISH1902', 'STUDENT', 'CS'),
('100230150', 'MOHAMMAD TAQUI ALAM', 'MOHAMMAD PARWEZ ALAM', 'MOHAMMAD7365', 'STUDENT', 'CS'),
('100230151', 'MOHIT KUMAR', 'RAJESH KUMAR', 'MOHIT4829', 'STUDENT', 'CS'),
('100230152', 'MUSKAN SINGH', 'RANJEET SINGH', 'MUSKAN2593', 'STUDENT', 'CS'),
('100230153', 'NIKHIL', 'RAM KUMAR', 'NIKHIL6817', 'STUDENT', 'CS'),
('100230154', 'NIKHIL GOUTAM', 'KARAN SINGH', 'NIKHIL3064', 'STUDENT', 'CS'),
('100230155', 'PIYUSH KUMAR', 'MR.SANJEEV KUMAR', 'PIYUSH9428', 'STUDENT', 'CS'),
('100230156', 'PREETI PRAJAPATI', 'ASHOK KUMAR', 'PREETI5792', 'STUDENT', 'CS'),
('100230157', 'PRINCE GUPTA', 'ROSHAN LAL GUPTA', 'PRINCE1356', 'STUDENT', 'CS'),
('100230158', 'PRIYANSH CHOUDHARY', 'KAMALDEEP CHOUDHARY', 'PRIYANSH8630', 'STUDENT', 'CS'),
('100230159', 'PRIYANSHI SRIVASTAVA', 'SANTOSH SRIVASTAVA', 'PRIYANSHI4285', 'STUDENT', 'CS'),
('100230160', 'RAJ DUBEY', 'RAMESH KUMAR DUBEY', 'RAJ7941', 'STUDENT', 'CS'),
('100230161', 'RAVI CHAUHAN', 'VINOD CHAUHAN', 'RAVI3175', 'STUDENT', 'CS'),
('100230162', 'RESHU GARG', 'ALOK GUPTA', 'RESHU9608', 'STUDENT', 'CS'),
('100230163', 'RIMJHIM', 'HARIOHM', 'RIMJHIM5432', 'STUDENT', 'CS'),
('100230164', 'RIMJHIM SINGH', 'SHRIPAL SINGH', 'RIMJHIM2796', 'STUDENT', 'CS'),
('100230165', 'RISHIT SINGH', 'YASHVEER SINGH', 'RISHIT8159', 'STUDENT', 'CS'),
('100230166', 'RITESH KUMAR', 'HARIKISHAN', 'RITESH4683', 'STUDENT', 'CS'),
('100230167', 'SAKSHAM SHARMA', 'LOKESH SHARMA', 'SAKSHAM1047', 'STUDENT', 'CS'),
('100230168', 'SANDEEP KUMAR YADAV', 'DINESH KUMAR YADAV', 'SANDEEP7514', 'STUDENT', 'CS'),
('100230169', 'SARGAM ARORA', 'RAJEEV ARORA', 'SARGAM3968', 'STUDENT', 'CS'),
('100230170', 'SATVIKA PANWAR', 'VIKAS PANWAR', 'SATVIKA6231', 'STUDENT', 'CS'),
('100230171', 'SATYAM KUMAR', 'OM PRAKASH', 'SATYAM8795', 'STUDENT', 'CS'),
('100230172', 'SAURABH PATEL', 'AJAY KUMAR PATEL', 'SAURABH2459', 'STUDENT', 'CS'),
('100230173', 'SAURABH SAROJ', 'HARISH CHANDRA SAROJ', 'SAURABH6012', 'STUDENT', 'CS'),
('100230174', 'SAURABH SINGH PATEL', 'HARIHAR SINGH', 'SAURABH3576', 'STUDENT', 'CS'),
('100230175', 'SAURABH TANWAR', 'RAVINDRA', 'SAURABH9840', 'STUDENT', 'CS'),
('100230176', 'SAURAV KUMAR', 'KRISHNA KUMAR', 'SAURAV1284', 'STUDENT', 'CS'),
('100230177', 'SHAVYA TYAGI', 'VIVEKANAND TYAGI', 'SHAVYA7648', 'STUDENT', 'CS'),
('100230178', 'SHIVANK SINGH KAUSHAL', 'RAM KUMAR AZAD', 'SHIVANK4903', 'STUDENT', 'CS'),
('100230179', 'SHUBHAM SHARMA', 'BHARAT SHARMA', 'SHUBHAM8367', 'STUDENT', 'CS'),
('100230180', 'SHUBHAM VISHWAKARMA', 'DHARMENDRA KUMAR VISHWAKARMA', 'SHUBHAM5721', 'STUDENT', 'CS'),
('100230181', 'SUKHVEER SINGH', 'GULFAN SINGH', 'SUKHVEER2085', 'STUDENT', 'CS'),
('100230182', 'TANISHA SINGH', 'RAKESH SINGH', 'TANISHA9549', 'STUDENT', 'CS'),
('100230183', 'VAIBHAV OJHA', 'SANTOSH KUMAR OJHA', 'VAIBHAV6173', 'STUDENT', 'CS'),
('100230184', 'VAISHNAVI PAL', 'DHARMENDRA KUMAR', 'VAISHNAVI3827', 'STUDENT', 'CS'),
('100230185', 'VANDANA YADAV', 'LALIT YADAV', 'VANDANA7491', 'STUDENT', 'CS'),
('100230186', 'VISHAL KUMAR', 'SHIV PRASAD', 'VISHAL1056', 'STUDENT', 'CS'),
('100230187', 'VIVEK GAUTAM', 'PRABHUNATH', 'VIVEK8410', 'STUDENT', 'CS'),
('100230188', 'VIVEK YADAV', 'MUSAFIR YADAV', 'VIVEK4674', 'STUDENT', 'CS'),
('100230189', 'YADI CHAUDHARY', 'HARENDRA SINGH', 'YADI2938', 'STUDENT', 'CS'),
('100230190', 'GOPESH SINGH', 'DEEPAK SINGH', 'GOPESH6502', 'STUDENT', 'CS'),
('100230191', 'ZEHRA BATOOL', 'MOHAMMAD HASSAN', 'ZEHRA3766', 'STUDENT', 'CS');

-- Insert 12 HODs for different departments
INSERT INTO users (user_id, name, father_name, password, role, department) VALUES
('HOD001', 'Dr. Rajesh Kumar Singh', 'Ramesh Kumar Singh', 'RAJESH9847', 'HOD', 'Computer Science'),
('HOD002', 'Dr. Priya Sharma', 'Suresh Sharma', 'PRIYA2563', 'HOD', 'Electronics'),
('HOD003', 'Dr. Amit Gupta', 'Mohan Gupta', 'AMIT7192', 'HOD', 'Mechanical'),
('HOD004', 'Dr. Sunita Verma', 'Prakash Verma', 'SUNITA4758', 'HOD', 'Civil'),
('HOD005', 'Dr. Vikash Yadav', 'Shyam Yadav', 'VIKASH8314', 'HOD', 'Electrical'),
('HOD006', 'Dr. Meera Agarwal', 'Dinesh Agarwal', 'MEERA1679', 'HOD', 'Chemical'),
('HOD007', 'Dr. Anoop Tiwari', 'Ramchandra Tiwari', 'ANOOP6025', 'HOD', 'Information Technology'),
('HOD008', 'Dr. Kavita Mishra', 'Jagdish Mishra', 'KAVITA3481', 'HOD', 'Biotechnology'),
('HOD009', 'Dr. Manoj Singh', 'Brijesh Singh', 'MANOJ9736', 'HOD', 'Aerospace'),
('HOD010', 'Dr. Ritu Pandey', 'Ashok Pandey', 'RITU5298', 'HOD', 'Environmental'),
('HOD011', 'Dr. Deepak Chaudhary', 'Vinod Chaudhary', 'DEEPAK8654', 'HOD', 'Automobile'),
('HOD012', 'Dr. Neha Jain', 'Sunil Jain', 'NEHA4127', 'HOD', 'Production');

-- Insert Faculty Members (6 per department = 72 total)
-- Computer Science Faculty
INSERT INTO users (user_id, name, father_name, password, role, department) VALUES
('FAC001', 'Prof. Sanjay Kumar', 'Ramesh Kumar', 'SANJAY3847', 'FACULTY', 'Computer Science'),
('FAC002', 'Dr. Pooja Singh', 'Mahesh Singh', 'POOJA7219', 'FACULTY', 'Computer Science'),
('FAC003', 'Prof. Rohit Sharma', 'Suresh Sharma', 'ROHIT5634', 'FACULTY', 'Computer Science'),
('FAC004', 'Dr. Nidhi Agarwal', 'Vinod Agarwal', 'NIDHI9182', 'FACULTY', 'Computer Science'),
('FAC005', 'Prof. Arun Verma', 'Prakash Verma', 'ARUN4573', 'FACULTY', 'Computer Science'),
('FAC006', 'Dr. Sneha Gupta', 'Rajesh Gupta', 'SNEHA8296', 'FACULTY', 'Computer Science'),

-- Electronics Faculty
('FAC007', 'Prof. Mukesh Yadav', 'Ram Yadav', 'MUKESH6471', 'FACULTY', 'Electronics'),
('FAC008', 'Dr. Rekha Mishra', 'Shyam Mishra', 'REKHA2958', 'FACULTY', 'Electronics'),
('FAC009', 'Prof. Vivek Pandey', 'Krishna Pandey', 'VIVEK7342', 'FACULTY', 'Electronics'),
('FAC010', 'Dr. Sapna Tiwari', 'Mohan Tiwari', 'SAPNA1685', 'FACULTY', 'Electronics'),
('FAC011', 'Prof. Dinesh Singh', 'Brijesh Singh', 'DINESH9738', 'FACULTY', 'Electronics'),
('FAC012', 'Dr. Preeti Jain', 'Sunil Jain', 'PREETI4051', 'FACULTY', 'Electronics'),

-- Mechanical Faculty
('FAC013', 'Prof. Ashok Kumar', 'Lakshman Kumar', 'ASHOK8264', 'FACULTY', 'Mechanical'),
('FAC014', 'Dr. Sunita Dubey', 'Harish Dubey', 'SUNITA3597', 'FACULTY', 'Mechanical'),
('FAC015', 'Prof. Ravi Chandra', 'Om Chandra', 'RAVI6830', 'FACULTY', 'Mechanical'),
('FAC016', 'Dr. Manju Pathak', 'Yatendra Pathak', 'MANJU2174', 'FACULTY', 'Mechanical'),
('FAC017', 'Prof. Naresh Gupta', 'Jagdish Gupta', 'NARESH7468', 'FACULTY', 'Mechanical'),
('FAC018', 'Dr. Kaveri Sharma', 'Suresh Sharma', 'KAVERI5031', 'FACULTY', 'Mechanical'),

-- Civil Faculty
('FAC019', 'Prof. Ramesh Pal', 'Chandra Pal', 'RAMESH8925', 'FACULTY', 'Civil'),
('FAC020', 'Dr. Anita Singh', 'Rajesh Singh', 'ANITA4358', 'FACULTY', 'Civil'),
('FAC021', 'Prof. Sunil Chauhan', 'Updesh Chauhan', 'SUNIL7612', 'FACULTY', 'Civil'),
('FAC022', 'Dr. Shweta Agarwal', 'Neeraj Agarwal', 'SHWETA2846', 'FACULTY', 'Civil'),
('FAC023', 'Prof. Manoj Tyagi', 'Sandeep Tyagi', 'MANOJ9179', 'FACULTY', 'Civil'),
('FAC024', 'Dr. Priyanka Verma', 'Mool Chandra', 'PRIYANKA5423', 'FACULTY', 'Civil'),

-- Electrical Faculty
('FAC025', 'Prof. Santosh Kumar', 'Narendra Kumar', 'SANTOSH7836', 'FACULTY', 'Electrical'),
('FAC026', 'Dr. Geeta Rastogi', 'Brijesh Rastogi', 'GEETA3260', 'FACULTY', 'Electrical'),
('FAC027', 'Prof. Vikas Kapil', 'Puneet Kapil', 'VIKAS8594', 'FACULTY', 'Electrical'),
('FAC028', 'Dr. Shanti Rajput', 'Jaidrath Singh', 'SHANTI4017', 'FACULTY', 'Electrical'),
('FAC029', 'Prof. Yogesh Yadav', 'Harishchandra Yadav', 'YOGESH7351', 'FACULTY', 'Electrical'),
('FAC030', 'Dr. Mira Singh', 'Sukhpal Singh', 'MIRA2684', 'FACULTY', 'Electrical'),

-- Chemical Faculty
('FAC031', 'Prof. Ajay Verma', 'Prakash Verma', 'AJAY6128', 'FACULTY', 'Chemical'),
('FAC032', 'Dr. Kiran Singh', 'Harswaroop Singh', 'KIRAN9472', 'FACULTY', 'Chemical'),
('FAC033', 'Prof. Umesh Shankar', 'Uma Shankar', 'UMESH3805', 'FACULTY', 'Chemical'),
('FAC034', 'Dr. Sushma Singh', 'Chandra Pal Singh', 'SUSHMA7139', 'FACULTY', 'Chemical'),
('FAC035', 'Prof. Praveen Kumar', 'Pradeep Kumar', 'PRAVEEN4563', 'FACULTY', 'Chemical'),
('FAC036', 'Dr. Ranjana Upadheyay', 'Radhe Krishan Upadheyay', 'RANJANA8927', 'FACULTY', 'Chemical'),

-- Information Technology Faculty
('FAC037', 'Prof. Neelesh Pal', 'Neelesh Kumar', 'NEELESH5291', 'FACULTY', 'Information Technology'),
('FAC038', 'Dr. Sudha Singh', 'Mukat Singh', 'SUDHA1675', 'FACULTY', 'Information Technology'),
('FAC039', 'Prof. Chander Kiran', 'Chand Kiran', 'CHANDER8048', 'FACULTY', 'Information Technology'),
('FAC040', 'Dr. Anju Singh', 'Kulbir Singh', 'ANJU3412', 'FACULTY', 'Information Technology'),
('FAC041', 'Prof. Pawan Kumar', 'Pawan', 'PAWAN6786', 'FACULTY', 'Information Technology'),
('FAC042', 'Dr. Seema Verma', 'Pramod Kumar', 'SEEMA2150', 'FACULTY', 'Information Technology'),

-- Biotechnology Faculty
('FAC043', 'Prof. Ramesh Chauhan', 'Ramesh Chauhan', 'RAMESH7534', 'FACULTY', 'Biotechnology'),
('FAC044', 'Dr. Kiran Tyagi', 'Sandeep Tyagi', 'KIRAN9068', 'FACULTY', 'Biotechnology'),
('FAC045', 'Prof. Dinesh Rathore', 'Dinesh Chandra Rathore', 'DINESH4281', 'FACULTY', 'Biotechnology'),
('FAC046', 'Dr. Babita Gupta', 'Bablu Gupta', 'BABITA8615', 'FACULTY', 'Biotechnology'),
('FAC047', 'Prof. Ramesh Sharma', 'Ramesh Kumar', 'RAMESH3949', 'FACULTY', 'Biotechnology'),
('FAC048', 'Dr. Parveen Alam', 'Mohammad Parwez Alam', 'PARVEEN7283', 'FACULTY', 'Biotechnology'),

-- Aerospace Faculty
('FAC049', 'Prof. Rajesh Patel', 'Rajesh Kumar', 'RAJESH5627', 'FACULTY', 'Aerospace'),
('FAC050', 'Dr. Ranjeet Singh', 'Ranjeet Singh', 'RANJEET1094', 'FACULTY', 'Aerospace'),
('FAC051', 'Prof. Ram Singh', 'Ram Kumar', 'RAM6458', 'FACULTY', 'Aerospace'),
('FAC052', 'Dr. Karan Goutam', 'Karan Singh', 'KARAN2832', 'FACULTY', 'Aerospace'),
('FAC053', 'Prof. Sanjeev Piyush', 'Sanjeev Kumar', 'SANJEEV9176', 'FACULTY', 'Aerospace'),
('FAC054', 'Dr. Ashok Prajapati', 'Ashok Kumar', 'ASHOK4540', 'FACULTY', 'Aerospace'),

-- Environmental Faculty
('FAC055', 'Prof. Roshan Gupta', 'Roshan Lal Gupta', 'ROSHAN8273', 'FACULTY', 'Environmental'),
('FAC056', 'Dr. Kamal Choudhary', 'Kamaldeep Choudhary', 'KAMAL3607', 'FACULTY', 'Environmental'),
('FAC057', 'Prof. Santosh Srivastava', 'Santosh Srivastava', 'SANTOSH6941', 'FACULTY', 'Environmental'),
('FAC058', 'Dr. Ramesh Dubey', 'Ramesh Kumar Dubey', 'RAMESH2384', 'FACULTY', 'Environmental'),
('FAC059', 'Prof. Vinod Ravi', 'Vinod Chauhan', 'VINOD7628', 'FACULTY', 'Environmental'),
('FAC060', 'Dr. Alok Reshu', 'Alok Gupta', 'ALOK5102', 'FACULTY', 'Environmental'),

-- Automobile Faculty
('FAC061', 'Prof. Hariohm Singh', 'Hariohm', 'HARIOHM8756', 'FACULTY', 'Automobile'),
('FAC062', 'Dr. Shripal Rimjhim', 'Shripal Singh', 'SHRIPAL4190', 'FACULTY', 'Automobile'),
('FAC063', 'Prof. Yashveer Rishit', 'Yashveer Singh', 'YASHVEER7534', 'FACULTY', 'Automobile'),
('FAC064', 'Dr. Harikishan Kumar', 'Harikishan', 'HARIKISHAN2867', 'FACULTY', 'Automobile'),
('FAC065', 'Prof. Lokesh Saksham', 'Lokesh Sharma', 'LOKESH6201', 'FACULTY', 'Automobile'),
('FAC066', 'Dr. Dinesh Sandeep', 'Dinesh Kumar Yadav', 'DINESH9545', 'FACULTY', 'Automobile'),

-- Production Faculty
('FAC067', 'Prof. Rajeev Sargam', 'Rajeev Arora', 'RAJEEV3872', 'FACULTY', 'Production'),
('FAC068', 'Dr. Vikas Satvika', 'Vikas Panwar', 'VIKAS8136', 'FACULTY', 'Production'),
('FAC069', 'Prof. Om Satyam', 'Om Prakash', 'OM4590', 'FACULTY', 'Production'),
('FAC070', 'Dr. Ajay Saurabh', 'Ajay Kumar Patel', 'AJAY7923', 'FACULTY', 'Production'),
('FAC071', 'Prof. Harish Saroj', 'Harish Chandra Saroj', 'HARISH2357', 'FACULTY', 'Production'),
('FAC072', 'Dr. Harihar Patel', 'Harihar Singh', 'HARIHAR6681', 'FACULTY', 'Production');

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_id ON users(user_id);
CREATE INDEX IF NOT EXISTS idx_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_department ON users(department);