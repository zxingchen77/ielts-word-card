import json
from pathlib import Path

# Original, concise study entries. This is a starter deck, not an official IELTS list.
raw = r'''学术核心|analyse|v.|分析|analyse data|Researchers analyse the data before drawing conclusions.
学术核心|assess|v.|评估；评价|assess the impact|The study assesses the impact of tourism on local communities.
学术核心|assume|v.|假定；认为|assume that|We should not assume that all students learn in the same way.
学术核心|approach|n.|方法；途径|a practical approach|A practical approach can help solve this problem.
学术核心|evidence|n.|证据；依据|strong evidence|There is strong evidence that exercise improves sleep.
学术核心|significant|adj.|显著的；重要的|a significant difference|There is a significant difference between the two groups.
学术核心|factor|n.|因素|a key factor|Cost is a key factor in choosing a university.
学术核心|indicate|v.|表明；显示|indicate a trend|The results indicate a growing demand for public transport.
学术核心|establish|v.|建立；确立|establish a link|The research establishes a link between diet and health.
学术核心|derive|v.|源于；获得|derive from|Many English words derive from Latin.
学术核心|interpret|v.|解释；理解|interpret the results|Different researchers may interpret the results differently.
学术核心|evaluate|v.|评价；评估|evaluate performance|Teachers use several methods to evaluate student performance.
学术核心|hypothesis|n.|假设|test a hypothesis|The experiment was designed to test this hypothesis.
学术核心|methodology|n.|研究方法；方法体系|research methodology|The report explains the research methodology in detail.
学术核心|consistent|adj.|一致的；持续的|consistent with|The findings are consistent with earlier studies.
学术核心|reliable|adj.|可靠的|reliable information|Students need access to reliable information.
学术核心|valid|adj.|有效的；有根据的|a valid argument|She presented a valid argument against the proposal.
学术核心|objective|adj.|客观的|an objective assessment|An objective assessment should consider both benefits and costs.
学术核心|perspective|n.|角度；观点|from a different perspective|Travel helps people see life from a different perspective.
学术核心|implication|n.|可能的影响；含义|long-term implications|The policy has long-term implications for education.
学术核心|underlying|adj.|根本的；潜在的|the underlying cause|We need to understand the underlying cause of the problem.
学术核心|illustrate|v.|说明；阐明|illustrate a point|This example illustrates the importance of careful planning.
学术核心|justify|v.|证明合理；为…提供理由|justify the cost|The benefits do not justify the cost of the project.
学术核心|relevant|adj.|相关的；切题的|relevant to|Work experience is relevant to many university courses.
学术核心|consequence|n.|结果；后果|an unintended consequence|An unintended consequence was a rise in housing costs.
学术核心|contribute|v.|贡献；促成|contribute to|Better public transport can contribute to cleaner air.
学术核心|distinguish|v.|区分；辨别|distinguish between|It is important to distinguish between facts and opinions.
学术核心|emphasise|v.|强调|emphasise the importance of|The report emphasises the importance of early education.
学术核心|comprehensive|adj.|全面的；详尽的|a comprehensive review|The committee conducted a comprehensive review of the policy.
学术核心|fundamental|adj.|基本的；根本的|a fundamental change|Digital technology has brought a fundamental change to communication.
教育|curriculum|n.|课程体系|the school curriculum|Financial education should be part of the school curriculum.
教育|tuition|n.|学费；教学|tuition fees|High tuition fees can discourage students from attending university.
教育|scholarship|n.|奖学金|receive a scholarship|She received a scholarship to study engineering.
教育|literacy|n.|读写能力|improve literacy|Public libraries play a role in improving literacy.
教育|numeracy|n.|计算能力|basic numeracy|Basic numeracy is essential in everyday life.
教育|qualification|n.|资格；学历|a professional qualification|A professional qualification can improve employment prospects.
教育|vocational|adj.|职业的；职业培训的|vocational training|Vocational training gives students practical skills.
教育|compulsory|adj.|义务的；强制的|compulsory education|Compulsory education ensures that children attend school.
教育|discipline|n.|纪律；学科|academic discipline|Economics is an academic discipline that studies resource allocation.
教育|motivation|n.|动力；积极性|student motivation|Clear goals can increase student motivation.
教育|concentration|n.|专注；集中|improve concentration|Regular breaks can improve concentration during study.
教育|assignment|n.|作业；任务|complete an assignment|Students must complete the assignment by Friday.
教育|lecture|n.|讲座；大学课堂授课|attend a lecture|Students can attend lectures online or in person.
教育|seminar|n.|研讨课；讨论会|a small-group seminar|A small-group seminar encourages students to exchange ideas.
教育|tutorial|n.|辅导课|a weekly tutorial|The weekly tutorial helps students clarify difficult concepts.
教育|assessment|n.|评估；考核|continuous assessment|Continuous assessment measures progress throughout the course.
教育|feedback|n.|反馈|constructive feedback|Constructive feedback helps learners improve their writing.
教育|memorise|v.|记忆；熟记|memorise vocabulary|It is easier to memorise vocabulary in context.
教育|critical|adj.|批判性的；关键的|critical thinking|Universities should encourage critical thinking.
教育|independent|adj.|独立的；自主的|independent learning|Independent learning prepares students for lifelong study.
教育|participation|n.|参与|active participation|Group projects encourage active participation.
教育|achievement|n.|成就；成绩|academic achievement|Family support can influence academic achievement.
教育|potential|n.|潜力|reach one's potential|Every child deserves the chance to reach their potential.
教育|mentor|n.|导师；指导者|an experienced mentor|An experienced mentor can guide a new teacher.
教育|apprenticeship|n.|学徒培训|complete an apprenticeship|He completed an apprenticeship in electrical engineering.
教育|graduate|n.|毕业生|a university graduate|A university graduate may still need practical work experience.
教育|undergraduate|n.|本科生|an undergraduate degree|She is studying for an undergraduate degree in biology.
教育|postgraduate|adj.|研究生的|postgraduate study|Postgraduate study often involves independent research.
教育|distance|n.|距离|distance learning|Distance learning makes education accessible to more people.
教育|peer|n.|同龄人；同伴|peer support|Peer support can help students adapt to university life.
环境|sustainable|adj.|可持续的|sustainable development|Sustainable development balances economic and environmental needs.
环境|biodiversity|n.|生物多样性|protect biodiversity|Protecting forests helps preserve biodiversity.
环境|habitat|n.|栖息地|natural habitat|Urban expansion can destroy the natural habitat of wildlife.
环境|conservation|n.|保护；保存|wildlife conservation|Wildlife conservation requires long-term investment.
环境|renewable|adj.|可再生的|renewable energy|Renewable energy can reduce dependence on fossil fuels.
环境|emission|n.|排放；排放物|carbon emissions|The city aims to reduce carbon emissions.
环境|pollution|n.|污染|air pollution|Air pollution affects the health of urban residents.
环境|deforestation|n.|森林砍伐|prevent deforestation|Stricter laws may help prevent deforestation.
环境|ecosystem|n.|生态系统|a fragile ecosystem|Pollution can damage a fragile ecosystem.
环境|drought|n.|干旱|a prolonged drought|A prolonged drought has reduced crop production.
环境|flood|n.|洪水|flood prevention|Flood prevention is a priority in coastal cities.
环境|resource|n.|资源|natural resources|Natural resources should be used responsibly.
环境|recycle|v.|回收利用|recycle household waste|Residents are encouraged to recycle household waste.
环境|landfill|n.|垃圾填埋场；填埋|landfill sites|Recycling reduces the amount of waste sent to landfill sites.
环境|biodegradable|adj.|可生物降解的|biodegradable packaging|Some companies use biodegradable packaging.
环境|contaminate|v.|污染；使受污染|contaminate water|Industrial waste can contaminate drinking water.
环境|deplete|v.|耗尽；大量消耗|deplete resources|Overfishing can deplete marine resources.
环境|preserve|v.|保护；保存|preserve forests|Local communities are working to preserve forests.
环境|extinction|n.|灭绝|face extinction|Some species face extinction because of habitat loss.
环境|endangered|adj.|濒危的|endangered species|National parks provide protection for endangered species.
环境|climate|n.|气候|climate change|Climate change presents challenges for agriculture.
环境|carbon|n.|碳|a carbon footprint|Using public transport can lower your carbon footprint.
环境|fossil|adj.|化石的|fossil fuels|Burning fossil fuels releases greenhouse gases.
环境|greenhouse|n.|温室|greenhouse gases|Greenhouse gases trap heat in the atmosphere.
环境|erosion|n.|侵蚀；流失|soil erosion|Planting trees can help prevent soil erosion.
环境|agriculture|n.|农业|sustainable agriculture|Sustainable agriculture protects soil and water.
环境|pesticide|n.|农药；杀虫剂|reduce pesticide use|Farmers are exploring ways to reduce pesticide use.
环境|organic|adj.|有机的|organic farming|Organic farming restricts the use of synthetic pesticides.
环境|waste|n.|废物；浪费|reduce food waste|Better planning can reduce food waste.
环境|ecological|adj.|生态的|ecological balance|The loss of predators can disturb the ecological balance.
科技|innovation|n.|创新|technological innovation|Technological innovation can create new industries.
科技|automation|n.|自动化|industrial automation|Industrial automation has changed the nature of factory work.
科技|artificial|adj.|人工的；人造的|artificial intelligence|Artificial intelligence is used in many translation tools.
科技|algorithm|n.|算法|a search algorithm|A search algorithm decides which results users see first.
科技|privacy|n.|隐私|protect privacy|Companies should protect the privacy of their customers.
科技|security|n.|安全；保障|data security|Strong passwords can improve data security.
科技|digital|adj.|数字的|digital skills|Digital skills are increasingly important in the workplace.
科技|access|n.|获取机会；使用权|internet access|Reliable internet access supports remote learning.
科技|device|n.|设备；装置|electronic devices|Electronic devices should be recycled safely.
科技|software|n.|软件|educational software|Educational software can provide personalised exercises.
科技|hardware|n.|硬件|computer hardware|Modern computer hardware uses less energy than older equipment.
科技|network|n.|网络|a wireless network|A wireless network allows devices to share information.
科技|database|n.|数据库|a research database|The library provides access to a research database.
科技|virtual|adj.|虚拟的|virtual reality|Virtual reality can help medical students practise procedures.
科技|remote|adj.|远程的；偏远的|remote work|Remote work allows employees to avoid long commutes.
科技|efficient|adj.|高效的|energy-efficient technology|Energy-efficient technology can reduce operating costs.
科技|obsolete|adj.|过时的；淘汰的|become obsolete|Some devices become obsolete within a few years.
科技|breakthrough|n.|重大突破|a scientific breakthrough|The discovery represents a scientific breakthrough.
科技|patent|n.|专利|apply for a patent|The inventor applied for a patent for the new device.
科技|prototype|n.|原型；样机|develop a prototype|Engineers developed a prototype before mass production.
科技|experiment|n.|实验|conduct an experiment|Scientists conducted an experiment to test the material.
科技|discovery|n.|发现|a major discovery|The telescope made a major discovery about distant planets.
科技|transmit|v.|传输；传播|transmit data|Satellites transmit data over long distances.
科技|storage|n.|存储；储藏|data storage|Cloud services offer flexible data storage.
科技|interact|v.|互动；相互作用|interact with|Online platforms allow students to interact with teachers.
科技|accessible|adj.|可使用的；易获得的|accessible to everyone|Public websites should be accessible to everyone.
科技|surveillance|n.|监控；监视|video surveillance|Video surveillance raises questions about privacy.
科技|cybercrime|n.|网络犯罪|prevent cybercrime|Better education can help users prevent cybercrime.
科技|robotics|n.|机器人技术|advances in robotics|Advances in robotics are changing manufacturing.
科技|infrastructure|n.|基础设施|digital infrastructure|Rural areas need investment in digital infrastructure.
社会|inequality|n.|不平等|income inequality|Income inequality can limit social mobility.
社会|diversity|n.|多样性|cultural diversity|Cultural diversity can enrich community life.
社会|community|n.|社区；群体|a local community|The local community helped organise the event.
社会|demographic|adj.|人口统计的|demographic change|Demographic change affects demand for public services.
社会|population|n.|人口|an ageing population|An ageing population creates new healthcare needs.
社会|migration|n.|移居；迁移|international migration|International migration can address labour shortages.
社会|integration|n.|融入；整合|social integration|Language classes can support social integration.
社会|discrimination|n.|歧视|age discrimination|Employers should take steps to prevent age discrimination.
社会|prejudice|n.|偏见|reduce prejudice|Education can help reduce prejudice.
社会|tolerance|n.|宽容；容忍|mutual tolerance|Mutual tolerance is important in a diverse society.
社会|welfare|n.|福利；福祉|social welfare|Social welfare programmes support vulnerable families.
社会|poverty|n.|贫困|reduce poverty|Education and employment can help reduce poverty.
社会|affordable|adj.|负担得起的|affordable housing|Young workers need access to affordable housing.
社会|volunteer|n.|志愿者|community volunteers|Community volunteers help elderly residents.
社会|charity|n.|慈善机构；慈善|a local charity|A local charity provides meals for people in need.
社会|cohesion|n.|凝聚力|social cohesion|Shared public spaces can strengthen social cohesion.
社会|isolation|n.|孤独；隔离|social isolation|Regular social activities can reduce social isolation.
社会|vulnerable|adj.|脆弱的；易受伤害的|vulnerable groups|Public services should protect vulnerable groups.
社会|policy|n.|政策|public policy|Public policy should be based on reliable evidence.
社会|legislation|n.|法律；立法|introduce legislation|The government introduced legislation to improve road safety.
社会|regulation|n.|法规；监管|safety regulations|Factories must follow strict safety regulations.
社会|enforce|v.|执行；实施|enforce the law|Authorities need resources to enforce the law.
社会|responsibility|n.|责任|social responsibility|Businesses have a social responsibility to local communities.
社会|citizen|n.|公民|active citizens|Active citizens can influence local decisions.
社会|participate|v.|参与|participate in|Residents are invited to participate in public meetings.
社会|equality|n.|平等|promote equality|Education can promote greater equality in society.
社会|mobility|n.|流动性；行动能力|social mobility|Affordable education can improve social mobility.
社会|urbanisation|n.|城市化|rapid urbanisation|Rapid urbanisation puts pressure on housing and transport.
社会|rural|adj.|农村的；乡村的|rural communities|Rural communities may have limited access to healthcare.
社会|household|n.|家庭；住户|household income|Household income influences spending on education.
经济工作|employment|n.|就业|employment opportunities|New businesses can create employment opportunities.
经济工作|unemployment|n.|失业|the unemployment rate|The unemployment rate fell after the economy recovered.
经济工作|productivity|n.|生产率；效率|increase productivity|Better training can increase productivity.
经济工作|inflation|n.|通货膨胀|rising inflation|Rising inflation reduces the purchasing power of wages.
经济工作|investment|n.|投资|public investment|Public investment can improve transport infrastructure.
经济工作|revenue|n.|收入；营收|tax revenue|Tax revenue helps fund public services.
经济工作|expenditure|n.|支出|government expenditure|Government expenditure on healthcare has increased.
经济工作|budget|n.|预算|a limited budget|The school must operate within a limited budget.
经济工作|consumer|n.|消费者|consumer demand|Consumer demand influences what companies produce.
经济工作|demand|n.|需求|meet demand|The company hired more staff to meet demand.
经济工作|supply|n.|供应；供给|supply and demand|Prices are influenced by supply and demand.
经济工作|competition|n.|竞争|market competition|Market competition can encourage innovation.
经济工作|enterprise|n.|企业|small enterprises|Small enterprises provide many local jobs.
经济工作|entrepreneur|n.|创业者；企业家|a young entrepreneur|The young entrepreneur started a recycling business.
经济工作|profit|n.|利润|make a profit|A business must earn enough revenue to make a profit.
经济工作|incentive|n.|激励；奖励|a financial incentive|A financial incentive can encourage energy savings.
经济工作|subsidy|n.|补贴|a government subsidy|A government subsidy can make public transport cheaper.
经济工作|taxation|n.|税收；征税|progressive taxation|Progressive taxation places higher rates on higher incomes.
经济工作|salary|n.|薪水|an annual salary|Graduates often consider salary when choosing a job.
经济工作|recruitment|n.|招聘|the recruitment process|The recruitment process includes an interview and a skills test.
经济工作|retention|n.|留用；保持|staff retention|Flexible hours may improve staff retention.
经济工作|flexible|adj.|灵活的|flexible working hours|Flexible working hours can help parents balance work and family.
经济工作|workforce|n.|劳动力；员工总数|a skilled workforce|A skilled workforce attracts investment.
经济工作|occupation|n.|职业|a demanding occupation|Nursing is a demanding occupation.
经济工作|promotion|n.|晋升；推广|career promotion|Training can improve a worker's chances of promotion.
经济工作|redundancy|n.|裁员；岗位被取消|face redundancy|Workers may face redundancy when a factory closes.
经济工作|globalisation|n.|全球化|economic globalisation|Economic globalisation connects markets around the world.
经济工作|trade|n.|贸易|international trade|International trade gives consumers access to more products.
经济工作|recession|n.|经济衰退|an economic recession|An economic recession can reduce business investment.
经济工作|prosperity|n.|繁荣；富裕|economic prosperity|Good infrastructure can support economic prosperity.
健康|nutrition|n.|营养|balanced nutrition|Balanced nutrition is important for healthy development.
健康|obesity|n.|肥胖|childhood obesity|Childhood obesity is a concern in many countries.
健康|sedentary|adj.|久坐的；缺少活动的|a sedentary lifestyle|A sedentary lifestyle can increase health risks.
健康|prevention|n.|预防|disease prevention|Disease prevention can reduce pressure on hospitals.
健康|diagnosis|n.|诊断|early diagnosis|Early diagnosis can improve treatment outcomes.
健康|treatment|n.|治疗|medical treatment|Everyone should have access to essential medical treatment.
健康|symptom|n.|症状|common symptoms|A cough and fever are common symptoms of some infections.
健康|chronic|adj.|慢性的；长期的|a chronic condition|A chronic condition may require ongoing care.
健康|infection|n.|感染|prevent infection|Handwashing can help prevent infection.
健康|immune|adj.|免疫的|the immune system|Adequate sleep supports the immune system.
健康|vaccination|n.|疫苗接种|a vaccination programme|A vaccination programme can protect public health.
健康|hygiene|n.|卫生|personal hygiene|Schools teach children the importance of personal hygiene.
健康|sanitation|n.|卫生设施；卫生处理|improve sanitation|Clean water and improved sanitation can reduce disease.
健康|wellbeing|n.|身心健康；福祉|mental wellbeing|Social support can improve mental wellbeing.
健康|anxiety|n.|焦虑|reduce anxiety|Regular exercise may help reduce anxiety.
健康|stress|n.|压力|work-related stress|Flexible schedules may reduce work-related stress.
健康|depression|n.|抑郁；抑郁症|treat depression|People should be able to access support to treat depression.
健康|therapy|n.|疗法；治疗|physical therapy|Physical therapy can help patients recover movement.
健康|rehabilitation|n.|康复|a rehabilitation programme|The rehabilitation programme helps patients return to daily life.
健康|addiction|n.|成瘾|tobacco addiction|Public health campaigns aim to reduce tobacco addiction.
健康|moderate|adj.|适度的|moderate exercise|Moderate exercise can benefit people of different ages.
健康|balanced|adj.|均衡的|a balanced diet|A balanced diet includes a variety of foods.
健康|intake|n.|摄入量|salt intake|Food labels help consumers understand their salt intake.
健康|deficiency|n.|缺乏；不足|a vitamin deficiency|A vitamin deficiency can affect a person's health.
健康|life expectancy|n.|预期寿命|average life expectancy|Average life expectancy has risen in many countries.
健康|mortality|n.|死亡率；死亡数量|infant mortality|Better healthcare can reduce infant mortality.
健康|epidemic|n.|流行病；疾病的流行|control an epidemic|Rapid action is needed to control an epidemic.
健康|healthcare|n.|医疗保健|public healthcare|Public healthcare is funded partly through taxation.
健康|patient|n.|病人|patient care|Hospitals need enough staff to provide good patient care.
健康|fitness|n.|身体健康；体能|physical fitness|Regular walking can improve physical fitness.
城市出行|congestion|n.|拥堵|traffic congestion|Traffic congestion wastes time and increases pollution.
城市出行|commute|v.|通勤|commute to work|Many residents commute to work by train.
城市出行|pedestrian|n.|行人|pedestrian safety|Lower speed limits can improve pedestrian safety.
城市出行|pavement|n.|人行道（英式）|a wide pavement|A wide pavement makes walking more comfortable.
城市出行|vehicle|n.|车辆|electric vehicles|Electric vehicles can reduce exhaust emissions in cities.
城市出行|route|n.|路线|a bus route|The new bus route connects the suburbs to the city centre.
城市出行|fare|n.|车费；票价|bus fares|Lower bus fares can encourage public transport use.
城市出行|suburb|n.|郊区|a residential suburb|The family lives in a residential suburb.
城市出行|accommodation|n.|住宿；住处|student accommodation|The university provides affordable student accommodation.
城市出行|residential|adj.|住宅的|a residential area|Heavy traffic should be restricted in residential areas.
城市出行|municipal|adj.|市政的|municipal services|Municipal services include waste collection and street cleaning.
城市出行|amenity|n.|便利设施|local amenities|Local amenities include parks, shops and libraries.
城市出行|facility|n.|设施|sports facilities|The council plans to build more sports facilities.
城市出行|construction|n.|建设；施工|road construction|Road construction may cause temporary delays.
城市出行|renovation|n.|翻新；整修|building renovation|Building renovation can improve energy efficiency.
城市出行|maintenance|n.|维护；保养|regular maintenance|Public transport requires regular maintenance.
城市出行|expansion|n.|扩张；扩建|urban expansion|Urban expansion can put pressure on farmland.
城市出行|density|n.|密度|population density|High population density can support frequent public transport.
城市出行|capacity|n.|容量；承载能力|passenger capacity|The new trains have greater passenger capacity.
城市出行|destination|n.|目的地|a tourist destination|The coastal town is a popular tourist destination.
城市出行|itinerary|n.|行程|a travel itinerary|A flexible travel itinerary allows time for unexpected delays.
城市出行|reservation|n.|预订|make a reservation|Visitors should make a reservation during the busy season.
城市出行|departure|n.|出发|the departure time|Passengers should check the departure time in advance.
城市出行|arrival|n.|到达|on arrival|Visitors receive a city map on arrival.
城市出行|transfer|n.|换乘；转移|an airport transfer|The hotel offers an airport transfer service.
城市出行|baggage|n.|行李|baggage allowance|Passengers should check their baggage allowance before travelling.
城市出行|heritage|n.|遗产|a heritage site|Tourism can provide funds to protect a heritage site.
城市出行|attraction|n.|景点；吸引力|a tourist attraction|The museum is a major tourist attraction.
城市出行|hospitality|n.|好客；酒店餐饮服务业|the hospitality industry|The hospitality industry provides jobs for local residents.
城市出行|overcrowding|n.|过度拥挤|reduce overcrowding|More frequent trains can reduce overcrowding.
文化媒体|tradition|n.|传统|local traditions|Festivals help preserve local traditions.
文化媒体|custom|n.|习俗|a cultural custom|Travellers should respect local cultural customs.
文化媒体|identity|n.|身份；认同|cultural identity|Language is closely connected to cultural identity.
文化媒体|multicultural|adj.|多元文化的|a multicultural society|A multicultural society includes people from different backgrounds.
文化媒体|diverse|adj.|多种多样的|a diverse audience|Public museums should appeal to a diverse audience.
文化媒体|artistic|adj.|艺术的|artistic expression|Schools can encourage artistic expression through music and drama.
文化媒体|creativity|n.|创造力|encourage creativity|Art lessons can encourage creativity in children.
文化媒体|exhibition|n.|展览|an art exhibition|The art exhibition attracted visitors from across the region.
文化媒体|museum|n.|博物馆|a public museum|A public museum can make history accessible to everyone.
文化媒体|preservation|n.|保护；保存|cultural preservation|Cultural preservation requires community involvement.
文化媒体|broadcast|v.|播送；广播|broadcast live|The concert was broadcast live on television.
文化媒体|journalism|n.|新闻工作；新闻业|investigative journalism|Investigative journalism can reveal problems in public institutions.
文化媒体|coverage|n.|报道；覆盖范围|media coverage|Media coverage can influence public attitudes.
文化媒体|bias|n.|偏见；偏向|media bias|Readers should be aware of possible media bias.
文化媒体|censorship|n.|审查；内容限制|media censorship|Media censorship can restrict access to information.
文化媒体|advertising|n.|广告；广告业|online advertising|Online advertising can reach a large audience.
文化媒体|persuade|v.|说服|persuade consumers|Advertisements often try to persuade consumers to buy products.
文化媒体|audience|n.|观众；受众|a younger audience|The programme was designed for a younger audience.
文化媒体|celebrity|n.|名人|celebrity endorsement|Celebrity endorsement can affect purchasing decisions.
文化媒体|influence|v.|影响|influence behaviour|Social media can influence consumer behaviour.
文化媒体|entertainment|n.|娱乐|digital entertainment|Digital entertainment has become part of everyday life.
文化媒体|documentary|n.|纪录片|a nature documentary|A nature documentary can raise awareness of conservation.
文化媒体|fiction|n.|小说；虚构作品|read fiction|Reading fiction can expose learners to different styles of language.
文化媒体|literature|n.|文学；文献|classic literature|Classic literature can provide insight into past societies.
文化媒体|translation|n.|翻译；译文|literary translation|Literary translation brings stories to new audiences.
文化媒体|linguistic|adj.|语言的；语言学的|linguistic diversity|Linguistic diversity is an important part of cultural heritage.
文化媒体|dialect|n.|方言|a local dialect|Some young people no longer speak the local dialect.
文化媒体|authentic|adj.|真实的；原真的|an authentic experience|Visitors often seek an authentic cultural experience.
文化媒体|commercial|adj.|商业的|commercial interests|Commercial interests can influence media content.
文化媒体|stereotype|n.|刻板印象|challenge stereotypes|Films can either reinforce or challenge stereotypes.
图表写作|increase|v.|增加|increase steadily|The number of visitors increased steadily over the period.
图表写作|decrease|v.|减少|decrease gradually|Water consumption decreased gradually after 2015.
图表写作|decline|n.|下降；衰退|a gradual decline|The chart shows a gradual decline in car sales.
图表写作|rise|n.|上升|a sharp rise|There was a sharp rise in electricity demand.
图表写作|fluctuate|v.|波动|fluctuate considerably|Oil prices fluctuated considerably during the year.
图表写作|stabilise|v.|稳定下来|stabilise at|The unemployment rate stabilised at five per cent.
图表写作|plateau|v.|趋于平稳；进入平台期|plateau at|Sales plateaued at around two thousand units per month.
图表写作|peak|v.|达到最高点|peak at|Visitor numbers peaked at ten thousand in August.
图表写作|trough|n.|最低点；低谷|reach a trough|The figure reached a trough in January.
图表写作|proportion|n.|比例|a large proportion|A large proportion of the budget was spent on healthcare.
图表写作|percentage|n.|百分比|the percentage of|The percentage of people cycling to work increased.
图表写作|ratio|n.|比率|the ratio of A to B|The ratio of men to women was approximately two to one.
图表写作|approximately|adv.|大约|approximately half|Approximately half of the respondents preferred online shopping.
图表写作|respectively|adv.|分别地；各自地|five and ten, respectively|The two cities recorded five and ten million visitors, respectively.
图表写作|whereas|conj.|然而；而|whereas the other|Car use increased, whereas bus use declined.
图表写作|compared|v.（过去分词）|比较|compared with|Sales doubled compared with the previous year.
图表写作|overall|adv.|总体上|overall trend|Overall, the figures show an upward trend.
图表写作|account for|phr. v.|占（比例）；解释|account for a third|Transport accounted for a third of household spending.
图表写作|double|v.|翻倍|double over a period|The population doubled over a twenty-year period.
图表写作|halve|v.|减半|halve over a period|The cost halved between 2010 and 2020.
图表写作|gradual|adj.|逐渐的|a gradual increase|The graph shows a gradual increase in average income.
图表写作|dramatic|adj.|急剧的；显著的|a dramatic fall|There was a dramatic fall in coal production.
图表写作|marginal|adj.|微小的|a marginal change|Only a marginal change occurred in the final year.
图表写作|steady|adj.|稳定的；持续的|steady growth|The region experienced steady growth in tourism.
图表写作|annual|adj.|每年的|annual expenditure|Annual expenditure on education rose throughout the period.
图表写作|average|n.|平均值|on average|Households spent more on food, on average, than on transport.
图表写作|range|n.|范围；区间|a wide range|The survey included people from a wide range of age groups.
图表写作|distribution|n.|分布|age distribution|The chart illustrates the age distribution of the population.
图表写作|projection|n.|预测；预计|a population projection|The population projection suggests further growth.
图表写作|trend|n.|趋势|an upward trend|An upward trend is visible in both countries.'''

words = []
for line in raw.strip().splitlines():
    theme, word, pos, meaning, collocation, example = line.split('|')
    words.append(dict(id=word.lower(), word=word, pos=pos, meaning=meaning,
                      collocation=collocation, example=example, theme=theme))
seen = {w['id'] for w in words}
for line in Path(__file__).with_name('extra_words.tsv').read_text(encoding='utf-8').splitlines():
    word, meaning, pos, theme = line.split('\t')
    ident = word.lower()
    if ident in seen:
        raise SystemExit(f'duplicate {word}')
    words.append(dict(id=ident, word=word, pos=pos, meaning=meaning,
                      collocation='', example='', theme=theme))
    seen.add(ident)
assert len(words) == 6000, len(words)
assert len(seen) == len(words)
assert all(w['meaning'] and len(w['word']) < 32 and len(w['meaning']) <= 300 and len(w['example']) < 150 for w in words)
Path(__file__).with_name('words.json').write_text(json.dumps(words, ensure_ascii=False, indent=2))
print(f'{len(words)} words, {len(set(w["theme"] for w in words))} themes')
