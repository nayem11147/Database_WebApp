create table if not exists suppliers (
    s_id int not null,
    name varchar(50),
    email varchar(50)
    primary key (s_id)
) engine = innodb;

create table if not exists supplier_tel (
    supp_id int not null,
    tel_number varchar(20),
    foreign key (supp_id) references suppliers(s_id)
) engine = innodb;

create table if not exists orders (
    o_id int not null primary key AUTO_INCREMENT,
    when_date date,
    supp_id int not null,
    foreign key (supp_id) REFERENCES suppliers(s_id)
);

create table if not exists order_items (
    order_id int not null,
    part_id int not null,
    qty int,
    foreign key (order_id) references orders(o_id),
    foreign key (part_id) references parts(_id)
);
