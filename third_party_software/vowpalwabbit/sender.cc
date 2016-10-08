#include <vector>
#ifdef _WIN32
#include <WinSock2.h>
#ifndef SHUT_RD
#   define SHUT_RD SD_RECEIVE
#endif

#ifndef SHUT_WR
#   define SHUT_WR SD_SEND
#endif

#ifndef SHUT_RDWR
#   define SHUT_RDWR SD_BOTH
#endif
#else
#include <netdb.h>
#endif
#include "io_buf.h"
#include "cache.h"
#include "network.h"
#include "reductions.h"

using namespace std;
struct sender
{ io_buf* buf;
  int sd;
  vw* all;//loss ring_size others
  example** delay_ring;
  size_t sent_index;
  size_t received_index;
};

void open_sockets(sender& s, string host)
{ s.sd = open_socket(host.c_str());
  s.buf = new io_buf();
  s.buf->files.push_back(s.sd);
}

void send_features(io_buf *b, example& ec, uint32_t mask)
{ // note: subtracting 1 b/c not sending constant
  output_byte(*b,(unsigned char) (ec.indices.size()-1));

  for (namespace_index ns : ec.indices)
  { if (ns == constant_namespace)
      continue;
    output_features(*b, ns, ec.feature_space[ns], mask);
  }
  b->flush();
}

void receive_result(sender& s)
{ float res, weight;

  get_prediction(s.sd,res,weight);
  example& ec = *s.delay_ring[s.received_index++ % s.all->p->ring_size];
  ec.pred.scalar = res;

  label_data& ld = ec.l.simple;
  ec.loss = s.all->loss->getLoss(s.all->sd, ec.pred.scalar, ld.label) * ec.weight;

  return_simple_example(*(s.all), nullptr, ec);
}

void learn(sender& s, LEARNER::base_learner&, example& ec)
{ if (s.received_index + s.all->p->ring_size / 2 - 1 == s.sent_index)
    receive_result(s);

  s.all->set_minmax(s.all->sd, ec.l.simple.label);
  s.all->p->lp.cache_label(&ec.l, *s.buf);//send label information.
  cache_tag(*s.buf, ec.tag);
  send_features(s.buf,ec, (uint32_t)s.all->parse_mask);
  s.delay_ring[s.sent_index++ % s.all->p->ring_size] = &ec;
}

void finish_example(vw&, sender&, example&) {}

void end_examples(sender& s)
{ //close our outputs to signal finishing.
  while (s.received_index != s.sent_index)
    receive_result(s);
  shutdown(s.buf->files[0],SHUT_WR);
}

void finish(sender& s)
{ s.buf->files.delete_v();
  s.buf->space.delete_v();
  free(s.delay_ring);
  delete s.buf;
}

LEARNER::base_learner* sender_setup(vw& all)
{ if (missing_option<string, true>(all, "sendto", "send examples to <host>"))
    return nullptr;

  sender& s = calloc_or_throw<sender>();
  s.sd = -1;
  if (all.vm.count("sendto"))
  { string host = all.vm["sendto"].as< string >();
    open_sockets(s, host);
  }

  s.all = &all;
  s.delay_ring = calloc_or_throw<example*>(all.p->ring_size);

  LEARNER::learner<sender>& l = init_learner(&s, learn, 1);
  l.set_finish(finish);
  l.set_finish_example(finish_example);
  l.set_end_examples(end_examples);
  return make_base(l);
}
